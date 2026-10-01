//
//  WallpaperWindowManager.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//

//import AppKit
//import SwiftUI
//import AVFoundation
//import CoreGraphics
//import OSLog
//
//@MainActor
//final class WallpaperWindowManager {
//
//    private var wallpaperWindows: [NSWindow] = []
//
//    private let logger = Logger(
//        subsystem: Bundle.main.bundleIdentifier ?? "MacLiveWallpaper",
//        category: "WallpaperEngine"
//    )
//
//    // MARK: - Show Wallpaper
//    func showWallpaper(player: AVPlayer,scalingMode: VideoScalingMode){
//
//        // Remove any wallpaper windows that already exist.
//        hideWallpaper()
//
//        let screens = NSScreen.screens
//
//        guard !screens.isEmpty else {
//            logger.error("No screens were detected.")
//            return
//        }
//
//        logger.info("Creating wallpaper windows for \(screens.count) screen(s).")
//
//        for screen in screens {
//            let window = createWallpaperWindow(
//                for: screen,
//                player: player,
//                scalingMode: scalingMode
//            )
//
//            wallpaperWindows.append(window)
//
//            // Put the wallpaper window on screen.
//            window.orderFrontRegardless()
//
//            logger.info(
//                "Wallpaper window created for display: \(screen.localizedName)"
//            )
//        }
//    }
//
//    // MARK: - Hide Wallpaper
//
//    func hideWallpaper() {
//
//        guard !wallpaperWindows.isEmpty else {
//            return
//        }
//
//        logger.info(
//            "Removing \(self.wallpaperWindows.count) wallpaper window(s)."
//        )
//
//        for window in wallpaperWindows {
//            window.orderOut(nil)
//            window.close()
//        }
//
//        wallpaperWindows.removeAll()
//    }
//
//    // MARK: - Create Wallpaper Window
//    private func createWallpaperWindow(
//        for screen: NSScreen,
//        player: AVPlayer,
//        scalingMode: VideoScalingMode
//    ) -> NSWindow{
//
//        let window = NSWindow(
//            contentRect: screen.frame,
//            styleMask: [.borderless],
//            backing: .buffered,
//            defer: false,
//            screen: screen
//        )
//
//        // ---------------------------------------------------------
//        // Basic appearance
//        // ---------------------------------------------------------
//
//        window.isOpaque = true
//        window.backgroundColor = .black
//        window.hasShadow = false
//
//        // ---------------------------------------------------------
//        // Wallpaper should never receive mouse clicks.
//        // ---------------------------------------------------------
//
//        window.ignoresMouseEvents = true
//        window.acceptsMouseMovedEvents = false
//
//        // ---------------------------------------------------------
//        // Desktop window level
//        // ---------------------------------------------------------
//        //
//        // Core Graphics provides a public desktop window level.
//        // This keeps our window at the desktop layer instead of
//        // using private WindowServer APIs.
//        //
//        // ---------------------------------------------------------
//
//        let desktopLevel = CGWindowLevelForKey(.desktopWindow)
//
//        window.level = NSWindow.Level(
//            rawValue: Int(desktopLevel)
//        )
//
//        // ---------------------------------------------------------
//        // Spaces / Mission Control behavior
//        // ---------------------------------------------------------
//
//        window.collectionBehavior = [
//            .canJoinAllSpaces,
//            .stationary,
//            .ignoresCycle
//        ]
//
//        // ---------------------------------------------------------
//        // Make the window exactly cover this display.
//        // ---------------------------------------------------------
//
//        window.setFrame(
//            screen.frame,
//            display: true
//        )
//
//        // ---------------------------------------------------------
//        // Put our SwiftUI video view inside the AppKit window.
//        // ---------------------------------------------------------
//        let videoView = VideoPlayerView(
//            player: player,
//            scalingMode: scalingMode
//        )
//        let hostingView = NSHostingView(
//            rootView: videoView
//        )
//
//        hostingView.frame = window.contentView?.bounds ?? screen.frame
//
//        hostingView.autoresizingMask = [
//            .width,
//            .height
//        ]
//
//        window.contentView = hostingView
//
//        return window
//    }
//}



import AppKit
import SwiftUI
import AVFoundation

@MainActor
final class WallpaperWindowManager {

    // MARK: - Properties

    private var windows: [CGDirectDisplayID: NSWindow] = [:]

    private var currentPlayer: AVPlayer?

    // MARK: - Initialization

    init() {
        startScreenChangeMonitoring()
    }

    // MARK: - Show Wallpaper

    /// Shows the current wallpaper on all connected displays.

    func showWallpaper(player: AVPlayer) {

        currentPlayer = player

        for screen in NSScreen.screens {
            show(
                on: screen,
                player: player
            )
        }
    }
    // MARK: - Hide Wallpaper

    /// Hides the wallpaper from all displays.
    func hideWallpaper() {
        for window in windows.values {
            window.orderOut(nil)
        }
    }

    // MARK: - Show On Specific Screen

    /// Shows the wallpaper on one specific display.
    func show(
        on screen: NSScreen,
        player: AVPlayer
    ) {
        currentPlayer = player

        let displayID = displayID(
            for: screen
        )

        // Reuse existing window.
        if let existingWindow = windows[displayID] {

            existingWindow.setFrame(
                screen.frame,
                display: true
            )

            updateContent(
                of: existingWindow,
                with: player
            )

            existingWindow.orderFrontRegardless()

            return
        }

        // Create a new wallpaper window.
        let window = createWallpaperWindow(
            for: screen,
            player: player
        )

        windows[displayID] = window

        window.orderFrontRegardless()
    }

    // MARK: - Show On Screen

    /// Shows the current player on a specific screen.
    func show(on screen: NSScreen) {
        guard let player = currentPlayer else {
            return
        }

        show(
            on: screen,
            player: player
        )
    }

    // MARK: - Create Wallpaper Window

    private func createWallpaperWindow(
        for screen: NSScreen,
        player: AVPlayer
    ) -> NSWindow {

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = NSWindow.Level(
            rawValue: Int(
                CGWindowLevelForKey(.desktopWindow)
            )
        )

        window.isOpaque = true
        window.backgroundColor = .black

        window.ignoresMouseEvents = true

        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary
        ]

        // MARK: Window Frame

        window.setFrame(
            screen.frame,
            display: true
        )

        // MARK: Window Level

        window.level = NSWindow.Level(
            rawValue: Int(
                CGWindowLevelForKey(.desktopWindow)
            )
        )

        // MARK: Spaces

        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle
        ]

        // MARK: Mouse

        window.ignoresMouseEvents = true

        // MARK: Appearance

        window.backgroundColor = .clear
        window.isOpaque = false

        // MARK: Window Behavior

        window.isMovable = false
        window.isExcludedFromWindowsMenu = true

        // MARK: SwiftUI Content

        let wallpaperView = VideoPlayerView(
            player: player
        )

        let hostingView = NSHostingView(
            rootView: wallpaperView
        )

        hostingView.frame = window.contentView?.bounds
            ?? screen.frame

        hostingView.autoresizingMask = [
            .width,
            .height
        ]

        window.contentView = hostingView

        return window
    }

    // MARK: - Update Content

    private func updateContent(
        of window: NSWindow,
        with player: AVPlayer
    ) {

        let wallpaperView = VideoPlayerView(
            player: player
        )

        let hostingView = NSHostingView(
            rootView: wallpaperView
        )

        hostingView.frame = window.contentView?.bounds
            ?? window.frame

        hostingView.autoresizingMask = [
            .width,
            .height
        ]

        window.contentView = hostingView
    }

    // MARK: - Update Displays

    func updateDisplays() {

        let screens = NSScreen.screens

        let connectedDisplayIDs = Set(
            screens.map {
                displayID(for: $0)
            }
        )

        // Remove windows belonging to disconnected displays.
        let removedDisplayIDs = windows.keys.filter {
            !connectedDisplayIDs.contains($0)
        }

        for id in removedDisplayIDs {

            windows[id]?.orderOut(nil)
            windows[id]?.close()

            windows.removeValue(
                forKey: id
            )
        }

        // Update existing displays.
        guard let player = currentPlayer else {
            return
        }

        for screen in screens {
            show(
                on: screen,
                player: player
            )
        }
    }

    // MARK: - Display ID

    private func displayID(
        for screen: NSScreen
    ) -> CGDirectDisplayID {

        screen.deviceDescription[
            NSDeviceDescriptionKey(
                "NSScreenNumber"
            )
        ] as? CGDirectDisplayID
        ?? CGMainDisplayID()
    }

    // MARK: - Screen Change Monitoring

    private func startScreenChangeMonitoring() {

        // We intentionally do not use
        // NotificationCenter.addObserver here.
        //
        // Swift 6 treats its callback as concurrently
        // executing code, which conflicts with @MainActor.

        Task { @MainActor [weak self] in

            let notifications =
                NotificationCenter.default.notifications(
                    named: NSApplication
                        .didChangeScreenParametersNotification
                )

            for await _ in notifications {

                guard !Task.isCancelled else {
                    break
                }

                self?.updateDisplays()
            }
        }
    }

    // MARK: - Close All Windows

    func closeAll() {

        for window in windows.values {

            window.orderOut(nil)
            window.close()
        }

        windows.removeAll()
    }
}
