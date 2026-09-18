import Foundation

struct AndroidDeviceService: Sendable {
    let locator: ToolLocator
    let runner: CommandRunner

    func devices() async throws -> [Device] {
        guard let adb = locator.locate("adb") else { throw CommandError.executableMissing("adb") }
        let result = try await runner.run(executable: adb, arguments: ["devices", "-l"])
        guard result.status == 0 else { throw CommandError.launchFailed(result.error) }

        return result.output.split(separator: "\n").dropFirst().compactMap { line in
            let fields = line.split(whereSeparator: \ .isWhitespace).map(String.init)
            guard fields.count >= 2 else { return nil }
            let serial = fields[0]
            let state = fields[1]
            let model = fields.first(where: { $0.hasPrefix("model:") })?
                .dropFirst("model:".count).replacingOccurrences(of: "_", with: " ")
            return Device(id: serial, name: model ?? serial, platform: .android, osVersion: nil, state: state)
        }
    }

    func install(_ package: AppPackage, on device: Device, options: InstallOptions) async throws -> CommandResult {
        guard case .apk(let url) = package else { throw CommandError.launchFailed("Android 设备只能安装 APK") }
        guard let adb = locator.locate("adb") else { throw CommandError.executableMissing("adb") }
        var arguments = ["-s", device.id, "install"]
        if options.replaceExisting { arguments.append("-r") }
        if options.allowDowngrade { arguments.append("-d") }
        if options.grantPermissions { arguments.append("-g") }
        arguments.append(url.path)
        return try await runner.run(executable: adb, arguments: arguments)
    }
}

struct IOSDeviceService: Sendable {
    let locator: ToolLocator
    let runner: CommandRunner

    func devices() async throws -> [Device] {
        guard let tool = locator.locate("idevice_id") else { throw CommandError.executableMissing("idevice_id") }
        let result = try await runner.run(executable: tool, arguments: ["-l"])
        guard result.status == 0 else { throw CommandError.launchFailed(result.error) }
        return result.output.split(whereSeparator: \ .isNewline).map {
            let id = String($0).trimmingCharacters(in: .whitespacesAndNewlines)
            return Device(id: id, name: "iPhone", platform: .ios, osVersion: nil, state: "connected")
        }
    }

    func install(_ package: AppPackage, on device: Device) async throws -> CommandResult {
        guard case .ipa(let url) = package else { throw CommandError.launchFailed("iOS 设备只能安装 IPA") }
        guard let tool = locator.locate("ideviceinstaller") else { throw CommandError.executableMissing("ideviceinstaller") }
        return try await runner.run(executable: tool, arguments: ["-u", device.id, "install", url.path])
    }
}
