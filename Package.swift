// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "QAInstallerMac",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "AppInstaller", targets: ["QAInstaller"]),
    ],
    targets: [
        .executableTarget(name: "QAInstaller", path: "Sources/QAInstaller"),
    ]
)
