//
//
//import SwiftUI
//import AppKit
//
//@main
//struct MacLiveWallpaperApp: App {
//
//    @StateObject private var loginItemManager =
//        LoginItemManager()
//
//    var body: some Scene {
//
//        // MARK: - Main Application Window
//
//        WindowGroup(id: "main") {
//            ContentView()
//        }
//
//        // MARK: - Menu Bar Application
//
//        MenuBarExtra(
//            "MAC LIVE WALLPAPER",
//            systemImage: "play.rectangle.fill"
//        ) {
//
//            MenuBarView(
//                isPlaying: false,
//                displayCount: 1,
//
//                // MARK: Login Item
//
//                loginItemEnabled:
//                    loginItemManager.isEnabled,
//
//                // MARK: Playback
//
//                onPlay: {
//                    // TODO:
//                    // Connect to wallpaper engine.
//                },
//
//                onPause: {
//                    // TODO:
//                    // Connect to wallpaper engine.
//                },
//
//                onStop: {
//                    // TODO:
//                    // Connect to wallpaper engine.
//                },
//
//                // MARK: Login Item Controls
//
//                onToggleLoginItem: {
//
//                    loginItemManager.toggle()
//                },
//
//                onOpenLoginItemsSettings: {
//
//                    loginItemManager.openLoginItemsSettings()
//                },
//
//                // MARK: Open Main Application
//
//                onOpenApp: {
//
//                    NSApp.activate(
//                        ignoringOtherApps: true
//                    )
//                },
//
//                // MARK: Quit
//
//                onQuit: {
//
//                    NSApp.terminate(nil)
//                }
//            )
//        }
//        .menuBarExtraStyle(.menu)
//    }
//}














//import SwiftUI
//import AppKit
//
//@main
//struct MacLiveWallpaperApp: App {
//
//    @NSApplicationDelegateAdaptor(AppDelegate.self)
//    private var appDelegate
//
//    @StateObject private var loginItemManager = LoginItemManager()
//
//    var body: some Scene {
//
//        // ---------------------------------------------------------
//        // Main application window
//        // ---------------------------------------------------------
//
//        WindowGroup(id: "main") {
//            ContentView()
//        }
//
//        // ---------------------------------------------------------
//        // Menu bar application
//        // ---------------------------------------------------------
//
//        MenuBarExtra(
//            "MAC LIVE WALLPAPER",
//            systemImage: "play.rectangle.fill"
//        ) {
//
//            MenuBarView(
//                isPlaying: false,
//                displayCount: NSScreen.screens.count,
//                loginItemEnabled: loginItemManager.isEnabled,
//
//                onPlay: {
//                    // Connected later to the shared wallpaper controller.
//                },
//
//                onPause: {
//                    // Connected later to the shared wallpaper controller.
//                },
//
//                onStop: {
//                    // Connected later to the shared wallpaper controller.
//                },
//
//                onToggleLoginItem: {
//                    loginItemManager.toggle()
//                },
//
//                onOpenLoginItemsSettings: {
//                    loginItemManager.openLoginItemsSettings()
//                },
//
//                onOpenApp: {
//                    appDelegate.openMainWindow()
//                },
//
//                onQuit: {
//                    NSApp.terminate(nil)
//                }
//            )
//        }
//        .menuBarExtraStyle(.menu)
//    }
//}
//
//// MARK: - NSApplicationDelegate
//
//final class AppDelegate: NSObject, NSApplicationDelegate {
//
//    func applicationDidFinishLaunching(
//        _ notification: Notification
//    ) {
//
//        // ---------------------------------------------------------
//        // IMPORTANT:
//        //
//        // Keep the application alive when its main window
//        // is closed.
//        // ---------------------------------------------------------
//
//        NSApp.setActivationPolicy(.accessory)
//
//        NSLog(
//            "MacLiveWallpaper launched."
//        )
//    }
//
//    func applicationShouldTerminateAfterLastWindowClosed(
//        _ sender: NSApplication
//    ) -> Bool {
//
//        // ---------------------------------------------------------
//        // FALSE = closing the red X does NOT quit the app.
//        //
//        // The menu bar item and wallpaper engine continue running.
//        // ---------------------------------------------------------
//
//        return false
//    }
//
//    func applicationSupportsSecureRestorableState(
//        _ app: NSApplication
//    ) -> Bool {
//
//        return true
//    }
//
//    // MARK: - Open Main Window
//
//    func openMainWindow() {
//
//        // Make the application active.
//        NSApp.activate(
//            ignoringOtherApps: true
//        )
//
//        // Find the main window if it already exists.
//        if let window = NSApp.windows.first(
//            where: { window in
//                window.identifier?.rawValue == "main"
//            }
//        ) {
//
//            window.makeKeyAndOrderFront(nil)
//            return
//        }
//
//        // If SwiftUI hasn't created it yet, ask it to create
//        // the WindowGroup window.
//        NSApp.sendAction(
//            #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
//            to: nil,
//            from: nil
//        )
//    }
//}


import SwiftUI
import AppKit

@main
struct MacLiveWallpaperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    // ============================================================
    // APP-LEVEL WALLPAPER ENGINE
    //
    // This object belongs to the application, NOT ContentView.
    //
    // Therefore closing the main window does not destroy the
    // wallpaper player.
    // ============================================================

    @StateObject private var appModel =
        WallpaperAppModel()

    @StateObject private var loginItemManager =
        LoginItemManager()

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
                    appModel
                        .playbackController
                        .isPlaying,

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

                    appModel.pauseWallpaper()
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
