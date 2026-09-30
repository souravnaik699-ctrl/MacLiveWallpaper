//
//  WallpaperWindowManager.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//

import AppKit
import SwiftUI
import AVFoundation
import CoreGraphics
import OSLog

@MainActor
final class WallpaperWindowManager {

    private var wallpaperWindows: [NSWindow] = []

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "MacLiveWallpaper",
        category: "WallpaperEngine"
    )

    // MARK: - Show Wallpaper

    func showWallpaper(player: AVPlayer) {

        // Remove any wallpaper windows that already exist.
        hideWallpaper()

        let screens = NSScreen.screens

        guard !screens.isEmpty else {
            logger.error("No screens were detected.")
            return
        }

        logger.info("Creating wallpaper windows for \(screens.count) screen(s).")

        for screen in screens {

            let window = createWallpaperWindow(
                for: screen,
                player: player
            )

            wallpaperWindows.append(window)

            // Put the wallpaper window on screen.
            window.orderFrontRegardless()

            logger.info(
                "Wallpaper window created for display: \(screen.localizedName)"
            )
        }
    }

    // MARK: - Hide Wallpaper

    func hideWallpaper() {

        guard !wallpaperWindows.isEmpty else {
            return
        }

        logger.info(
            "Removing \(self.wallpaperWindows.count) wallpaper window(s)."
        )

        for window in wallpaperWindows {
            window.orderOut(nil)
            window.close()
        }

        wallpaperWindows.removeAll()
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
            defer: false,
            screen: screen
        )

        // ---------------------------------------------------------
        // Basic appearance
        // ---------------------------------------------------------

        window.isOpaque = true
        window.backgroundColor = .black
        window.hasShadow = false

        // ---------------------------------------------------------
        // Wallpaper should never receive mouse clicks.
        // ---------------------------------------------------------

        window.ignoresMouseEvents = true
        window.acceptsMouseMovedEvents = false

        // ---------------------------------------------------------
        // Desktop window level
        // ---------------------------------------------------------
        //
        // Core Graphics provides a public desktop window level.
        // This keeps our window at the desktop layer instead of
        // using private WindowServer APIs.
        //
        // ---------------------------------------------------------

        let desktopLevel = CGWindowLevelForKey(.desktopWindow)

        window.level = NSWindow.Level(
            rawValue: Int(desktopLevel)
        )

        // ---------------------------------------------------------
        // Spaces / Mission Control behavior
        // ---------------------------------------------------------

        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle
        ]

        // ---------------------------------------------------------
        // Make the window exactly cover this display.
        // ---------------------------------------------------------

        window.setFrame(
            screen.frame,
            display: true
        )

        // ---------------------------------------------------------
        // Put our SwiftUI video view inside the AppKit window.
        // ---------------------------------------------------------

        let videoView = VideoPlayerView(
            player: player
        )

        let hostingView = NSHostingView(
            rootView: videoView
        )

        hostingView.frame = window.contentView?.bounds ?? screen.frame

        hostingView.autoresizingMask = [
            .width,
            .height
        ]

        window.contentView = hostingView

        return window
    }
}
