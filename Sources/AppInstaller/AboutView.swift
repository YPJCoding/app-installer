import AppKit
import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private let repositoryURL = URL(string: "https://github.com/YPJCoding/app-installer")!

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .accessibilityHidden(true)

            VStack(spacing: 5) {
                Text("App Installer")
                    .font(.title2.weight(.semibold))
                Text(versionDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("适用于 Android 与 iOS 设备的应用安装工具")
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                LabeledContent("作者", value: "杨鹏举")
                LabeledContent("开源仓库") {
                    Link(destination: repositoryURL) {
                        HStack(spacing: 4) {
                            Text("github.com/YPJCoding/app-installer")
                            Image(systemName: "arrow.up.right.square")
                        }
                    }
                }
            }
            .frame(maxWidth: 340)

            Button("完成") { dismiss() }
                .keyboardShortcut(.defaultAction)
        }
        .padding(28)
        .frame(width: 440)
    }

    private var versionDescription: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String
        let build = info?["CFBundleVersion"] as? String

        switch (version, build) {
        case let (version?, build?) where !version.isEmpty && !build.isEmpty:
            return "版本 \(version)（\(build)）"
        case let (version?, _):
            return "版本 \(version)"
        default:
            return "开发版本"
        }
    }
}
