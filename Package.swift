// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "QAInstallerMac",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "AppInstaller", targets: ["QAInstaller"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.10.0"),
    ],
    targets: [
        .executableTarget(
            name: "QAInstaller",
            dependencies: [.product(name: "Sparkle", package: "Sparkle")],
            path: "Sources/QAInstaller",
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"]),
            ]
        ),
    ]
)
