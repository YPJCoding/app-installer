import Foundation

enum CommandError: LocalizedError {
    case executableMissing(String)
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case .executableMissing(let name): "未找到 \(name)"
        case .launchFailed(let message): "命令启动失败：\(message)"
        }
    }
}

struct ToolLocator: Sendable {
    private let searchDirectories = [
        "/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin"
    ]

    func locate(_ name: String) -> String? {
        if let resourceURL = Bundle.main.resourceURL {
            let bundled = resourceURL
                .appendingPathComponent("Tools/bin", isDirectory: true)
                .appendingPathComponent(name).path
            if FileManager.default.isExecutableFile(atPath: bundled) { return bundled }
        }
        return searchDirectories
            .map { URL(fileURLWithPath: $0).appendingPathComponent(name).path }
            .first { FileManager.default.isExecutableFile(atPath: $0) }
    }
}

struct CommandRunner: Sendable {
    func run(executable: String, arguments: [String]) async throws -> CommandResult {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            let stdout = Pipe()
            let stderr = Pipe()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            if let resourceURL = Bundle.main.resourceURL {
                let tools = resourceURL.appendingPathComponent("Tools", isDirectory: true)
                var environment = ProcessInfo.processInfo.environment
                environment["PATH"] = tools.appendingPathComponent("bin").path + ":" + (environment["PATH"] ?? "/usr/bin:/bin")
                environment["DYLD_LIBRARY_PATH"] = tools.appendingPathComponent("lib").path
                process.environment = environment
            }
            process.standardOutput = stdout
            process.standardError = stderr

            do { try process.run() }
            catch { throw CommandError.launchFailed(error.localizedDescription) }

            let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
            let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return CommandResult(
                output: String(decoding: outputData, as: UTF8.self),
                error: String(decoding: errorData, as: UTF8.self),
                status: process.terminationStatus
            )
        }.value
    }
}
