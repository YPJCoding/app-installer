import AppKit
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var devices: [Device] = []
    @Published var selectedDeviceID: Device.ID?
    @Published var package: AppPackage?
    @Published var options = InstallOptions()
    @Published var phase: InstallPhase = .idle
    @Published var logs: [String] = []
    @Published var statusMessage = "连接手机，然后选择或拖入 APK / IPA。"
    @Published var dependencyWarnings: [String] = []

    private let locator = ToolLocator()
    private let runner = CommandRunner()
    private var isRefreshingDevices = false

    var selectedDevice: Device? { devices.first { $0.id == selectedDeviceID } }
    var canInstall: Bool {
        guard phase != .installing, let package, let device = selectedDevice else { return false }
        return device.isReady && package.platform == device.platform
    }

    func monitorDevices() async {
        await refreshDevices()
        while !Task.isCancelled {
            do { try await Task.sleep(for: .seconds(2)) }
            catch { break }
            if phase != .installing {
                await refreshDevices(showProgress: false)
            }
        }
    }

    func choosePackage() {
        let panel = NSOpenPanel()
        panel.title = "选择安装包"
        panel.message = "支持 Android APK 与 iOS IPA。"
        panel.allowedContentTypes = [.data]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url { accept(url: url) }
    }

    func accept(url: URL) {
        guard let value = AppPackage(url: url) else {
            statusMessage = "不支持该文件，请选择 .apk 或 .ipa。"
            return
        }
        package = value
        statusMessage = "已选择 \(value.displayName)"
        if let matching = devices.first(where: { $0.platform == value.platform && $0.isReady }) {
            selectedDeviceID = matching.id
        }
    }

    func refreshDevices(showProgress: Bool = true) async {
        guard phase != .installing, !isRefreshingDevices else { return }
        isRefreshingDevices = true
        defer {
            isRefreshingDevices = false
            if showProgress, phase == .refreshing { phase = .idle }
        }
        if showProgress { phase = .refreshing }
        async let androidResult = discoverAndroid()
        async let iosResult = discoverIOS()
        let (android, ios) = await (androidResult, iosResult)
        let discoveredDevices = (android.devices + ios.devices).sorted {
            if $0.platform.rawValue != $1.platform.rawValue {
                return $0.platform.rawValue < $1.platform.rawValue
            }
            return $0.id < $1.id
        }
        let discoveredWarnings = android.warnings + ios.warnings
        let deviceListChanged = discoveredDevices != devices
        let warningsChanged = discoveredWarnings != dependencyWarnings
        let previousSelection = selectedDeviceID
        let selectedDeviceWasRemoved = previousSelection != nil
            && !discoveredDevices.contains(where: { $0.id == previousSelection })
        if deviceListChanged { devices = discoveredDevices }
        if warningsChanged { dependencyWarnings = discoveredWarnings }
        if selectedDeviceWasRemoved {
            resetInstallSession()
            selectedDeviceID = bestDeviceSelection()
        } else if !devices.contains(where: { $0.id == selectedDeviceID }) {
            selectedDeviceID = bestDeviceSelection()
        }
        if selectedDeviceWasRemoved {
            statusMessage = devices.isEmpty ? "设备已断开，请连接手机。" : "设备已切换，请选择安装包。"
        } else if showProgress || deviceListChanged {
            statusMessage = devices.isEmpty ? "没有发现设备，请检查连接与授权。" : "发现 \(devices.count) 台设备。"
        }
    }

    func install() {
        guard canInstall, let package, let device = selectedDevice else { return }
        phase = .installing
        logs = ["开始安装 \(package.displayName)", "目标设备：\(device.name) (\(device.id))"]
        statusMessage = "正在安装，请保持设备连接…"
        let android = AndroidDeviceService(locator: locator, runner: runner)
        let ios = IOSDeviceService(locator: locator, runner: runner)
        Task {
            do {
                let result = switch device.platform {
                case .android: try await android.install(package, on: device, options: options)
                case .ios: try await ios.install(package, on: device)
                }
                appendOutput(result.output)
                appendOutput(result.error)
                if result.status == 0 {
                    phase = .succeeded
                    statusMessage = "安装成功"
                    logs.append("✓ 安装成功")
                } else {
                    phase = .failed
                    statusMessage = ErrorTranslator.message(for: result.output + "\n" + result.error)
                    logs.append("✗ 安装失败（退出码 \(result.status)）")
                }
            } catch {
                phase = .failed
                statusMessage = ErrorTranslator.message(for: error.localizedDescription)
                logs.append("✗ \(error.localizedDescription)")
            }
        }
    }

    func clearPackage() {
        resetInstallSession()
        statusMessage = "连接手机，然后选择或拖入 APK / IPA。"
    }

    private func resetInstallSession() {
        package = nil
        logs = []
        phase = .idle
    }

    private func bestDeviceSelection() -> Device.ID? {
        if let package {
            return devices.first(where: { $0.platform == package.platform && $0.isReady })?.id
        }
        return devices.first(where: \ .isReady)?.id ?? devices.first?.id
    }

    private func appendOutput(_ output: String) {
        logs.append(contentsOf: output.split(whereSeparator: \ .isNewline).map(String.init))
    }

    private func discoverAndroid() async -> (devices: [Device], warnings: [String]) {
        do { return (try await AndroidDeviceService(locator: locator, runner: runner).devices(), []) }
        catch { return ([], [ErrorTranslator.message(for: error.localizedDescription)]) }
    }

    private func discoverIOS() async -> (devices: [Device], warnings: [String]) {
        do { return (try await IOSDeviceService(locator: locator, runner: runner).devices(), []) }
        catch { return ([], [ErrorTranslator.message(for: error.localizedDescription)]) }
    }
}
