import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var state = AppState()
    @State private var isDropTarget = false
    @State private var isShowingAbout = false

    var body: some View {
        HSplitView {
            deviceSidebar.frame(minWidth: 250, idealWidth: 285, maxWidth: 330)
            VStack(spacing: 0) {
                packageArea
                Divider()
                logArea.frame(minHeight: 180, idealHeight: 220)
            }
        }
        .task { await state.monitorDevices() }
        .toolbar {
            ToolbarItemGroup {
                Button { Task { await state.refreshDevices() } } label: {
                    Label("刷新设备", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r")
                .disabled(state.phase == .installing || state.phase == .refreshing)
                Button { isShowingAbout = true } label: {
                    Label("关于 App Installer", systemImage: "info.circle")
                }
                .help("关于 App Installer")
            }
        }
        .sheet(isPresented: $isShowingAbout) {
            AboutView()
        }
    }

    private var deviceSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("已连接设备").font(.headline).padding([.horizontal, .top], 16).padding(.bottom, 8)
            if state.devices.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "cable.connector")
                        .font(.system(size: 40)).foregroundStyle(.secondary)
                    Text("未发现设备").font(.headline)
                    Text("连接并解锁手机，然后刷新设备。")
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List(state.devices, selection: $state.selectedDeviceID) { device in
                    HStack(spacing: 12) {
                        PlatformLogo(platform: device.platform, isReady: device.isReady)
                            .frame(width: 30, height: 30)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(device.name).fontWeight(.medium).lineLimit(1)
                            Text(device.subtitle).font(.caption).foregroundStyle(.secondary)
                            Text(device.id).font(.caption2.monospaced()).foregroundStyle(.tertiary).lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4).tag(device.id)
                }
                .listStyle(.sidebar)
            }
            if !state.dependencyWarnings.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(state.dependencyWarnings, id: \.self) { warning in
                        Label(warning, systemImage: "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(12).background(.bar)
            }
        }
    }

    private var packageArea: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 20)
            Image(systemName: state.package == nil ? "square.and.arrow.down.on.square" : "shippingbox.fill")
                .font(.system(size: 54, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isDropTarget ? Color.accentColor : .secondary)
            if let package = state.package {
                Text(package.displayName).font(.title2.weight(.semibold)).lineLimit(1)
                Label(package.platform == .android ? "Android APK" : "iOS IPA", systemImage: package.platform.symbol)
                    .foregroundStyle(.secondary)
                if package.platform == .android { androidOptions }
                compatibilityNotice(package)
            } else {
                Text("将 APK / IPA 拖到这里").font(.title2.weight(.semibold))
                Text("也可以点击下方按钮选择安装包").foregroundStyle(.secondary)
                Button("选择安装包…") { state.choosePackage() }.buttonStyle(.bordered)
            }
            Text(state.statusMessage)
                .foregroundStyle(state.phase == .failed ? .red : state.phase == .succeeded ? .green : .secondary)
                .multilineTextAlignment(.center).frame(maxWidth: 560)
            if state.package != nil {
                HStack {
                    Button("移除", role: .cancel) { state.clearPackage() }
                    Button { state.install() } label: {
                        if state.phase == .installing { ProgressView().controlSize(.small) }
                        Text(state.phase == .installing ? "正在安装" : "安装")
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large).disabled(!state.canInstall)
                }
            }
            Spacer(minLength: 20)
        }
        .padding(30).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isDropTarget ? Color.accentColor.opacity(0.08) : Color.clear)
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            state.accept(url: url); return state.package != nil
        } isTargeted: { isDropTarget = $0 }
    }

    private var androidOptions: some View {
        HStack(spacing: 18) {
            Toggle("覆盖安装", isOn: $state.options.replaceExisting)
            Toggle("允许降级", isOn: $state.options.allowDowngrade)
            Toggle("自动授予权限", isOn: $state.options.grantPermissions)
        }
        .toggleStyle(.checkbox)
    }

    private func compatibilityNotice(_ package: AppPackage) -> some View {
        Group {
            if let device = state.selectedDevice, device.platform != package.platform {
                Label("安装包与所选设备类型不匹配", systemImage: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
            } else if state.selectedDevice == nil {
                Label("请先连接并选择一台 \(package.platform.rawValue) 设备", systemImage: "info.circle")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var logArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("安装日志").font(.headline)
                Spacer()
                if !state.logs.isEmpty {
                    Button("清空") { state.logs = [] }.buttonStyle(.plain).foregroundStyle(.secondary)
                }
            }
            ScrollView {
                Text(state.logs.isEmpty ? "尚无日志" : state.logs.joined(separator: "\n"))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(state.logs.isEmpty ? .tertiary : .primary)
                    .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .padding(10).background(.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
    }
}

private struct PlatformLogo: View {
    let platform: DevicePlatform
    let isReady: Bool

    var body: some View {
        brandImage
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(logoColor)
            .padding(platform == .android ? 1 : 2)
            .accessibilityLabel(platform.rawValue)
    }

    private var logoColor: Color {
        guard isReady else { return .orange }
        return platform == .android
            ? Color(red: 0.24, green: 0.86, blue: 0.52)
            : .primary
    }

    private var brandImage: Image {
        let name = platform == .android ? "android" : "apple"
        if let url = Bundle.main.url(forResource: name, withExtension: "svg", subdirectory: "PlatformLogos"),
           let image = NSImage(contentsOf: url) {
            return Image(nsImage: image)
        }
        return Image(systemName: platform == .android ? "phone.fill" : "apple.logo")
    }
}
