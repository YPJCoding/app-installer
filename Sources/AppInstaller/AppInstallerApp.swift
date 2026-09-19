import SwiftUI
import Sparkle

@main
struct AppInstallerApp: App {
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 850, minHeight: 620)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("关于 App Installer") {
                    AboutPanel.show()
                }
            }
            CommandGroup(after: .appInfo) {
                Button("检查更新…") {
                    updaterController.updater.checkForUpdates()
                }
            }
        }
    }
}
