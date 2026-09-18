import Foundation

enum DevicePlatform: String, Codable, Sendable {
    case android = "Android"
    case ios = "iOS"

    var symbol: String { self == .android ? "phone.fill" : "iphone" }
}

struct Device: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let platform: DevicePlatform
    let osVersion: String?
    let state: String

    var isReady: Bool { state == "device" || state == "connected" }
    var subtitle: String {
        let version = osVersion.map { "\(platform.rawValue) \($0)" } ?? platform.rawValue
        return isReady ? version : "\(version) · \(state)"
    }
}

enum AppPackage: Equatable, Sendable {
    case apk(URL)
    case ipa(URL)

    var url: URL {
        switch self { case .apk(let url), .ipa(let url): url }
    }
    var platform: DevicePlatform { if case .apk = self { return .android }; return .ios }
    var displayName: String { url.lastPathComponent }

    init?(url: URL) {
        switch url.pathExtension.lowercased() {
        case "apk": self = .apk(url)
        case "ipa": self = .ipa(url)
        default: return nil
        }
    }
}

struct InstallOptions: Sendable {
    var replaceExisting = true
    var allowDowngrade = false
    var grantPermissions = false
}

struct CommandResult: Sendable {
    let output: String
    let error: String
    let status: Int32
}

enum InstallPhase: Equatable {
    case idle, refreshing, installing, succeeded, failed
}
