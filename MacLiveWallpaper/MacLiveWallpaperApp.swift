

import SwiftUI
import AppKit

@main
struct MacLiveWallpaperApp: App {

    @StateObject private var appCoordinator: AppCoordinator
    @StateObject private var appModel: WallpaperAppModel

    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    @StateObject private var loginItemManager =
        LoginItemManager()

    @StateObject private var systemEventMonitor =
        SystemEventMonitor()

    init() {

        AppSettingsDefaults.register()

        let coordinator =
            AppCoordinator()

        _appCoordinator =
            StateObject(
                wrappedValue:
                    coordinator
            )

        _appModel =
            StateObject(
                wrappedValue:
                    WallpaperAppModel(
                        appCoordinator:
                            coordinator
                    )
            )
    }

    var body: some Scene {

        // ========================================================
        // MAIN WINDOW
        // ========================================================

        WindowGroup(id: "main") {

            ContentView()
                .environmentObject(appModel)
        }

        // ========================================================
        // MENU BAR
        // ========================================================

        MenuBarExtra(
            "MAC LIVE WALLPAPER",
            systemImage:
                "play.rectangle.fill"
        ) {

            MenuBarView(

                isPlaying:
                    appModel.isLiveWallpaperPlaying,

                displayCount:
                    NSScreen.screens.count,

                loginItemEnabled:
                    loginItemManager.isEnabled,

                // ------------------------------------------------
                // PLAY
                // ------------------------------------------------

                onPlay: {

                    appModel.resumeWallpaper()
                },

                // ------------------------------------------------
                // PAUSE
                // ------------------------------------------------

                onPause: {

                    appModel.pauseAllDisplays()
                },

                // ------------------------------------------------
                // STOP
                // ------------------------------------------------

                onStop: {

                    appModel.stopWallpaper()
                },

                // ------------------------------------------------
                // LOGIN ITEM
                // ------------------------------------------------

                onToggleLoginItem: {

                    loginItemManager.toggle()
                },

                onOpenLoginItemsSettings: {

                    loginItemManager
                        .openLoginItemsSettings()
                },

                // ------------------------------------------------
                // OPEN APPLICATION WINDOW
                // ------------------------------------------------

                onOpenApp: {

                    NSApp.activate(
                        ignoringOtherApps: true
                    )

                    if let window =
                        NSApp.windows.first(
                            where: {
                                !$0.isMiniaturized &&
                                $0.canBecomeKey
                            }
                        ) {

                        window.makeKeyAndOrderFront(nil)
                    }
                },

                // ------------------------------------------------
                // QUIT
                // ------------------------------------------------

                onQuit: {

                    NSApp.terminate(nil)
                }
            )
        }
        .menuBarExtraStyle(.menu)
        Settings {
            SettingsView()
        }
    }
}

// MARK: - NSApplicationDelegate

final class AppDelegate:
    NSObject,
    NSApplicationDelegate {

    // ============================================================
    // APPLICATION LAUNCH
    // ============================================================

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {

        /*
         Accessory application:

         - Application continues running.
         - Menu bar item remains available.
         - Closing the main window does not quit the process.
         */

        NSApp.setActivationPolicy(
            .accessory
        )

        NSLog(
            "MacLiveWallpaper application started."
        )
    }

    // ============================================================
    // CRITICAL
    // ============================================================

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {

        /*
         FALSE IS IMPORTANT.

         Closing:

             Main Window
                    ↓
                 Red X
                    ↓
             Window disappears
                    ↓
             Application stays alive
                    ↓
             Wallpaper continues
         */

        return false
    }

    // ============================================================
    // STATE RESTORATION
    // ============================================================

    func applicationSupportsSecureRestorableState(
        _ app: NSApplication
    ) -> Bool {

        return true
    }
}
