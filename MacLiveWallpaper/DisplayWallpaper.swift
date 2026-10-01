//
//  DisplayWallpaper.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//

import AppKit
import Foundation
import OSLog

@MainActor
final class DisplayWallpaper {

    // MARK: - Properties

    let displayID: CGDirectDisplayID

    let windowManager: WallpaperWindowManager

    let playbackController: VideoPlayerController
    
    private let staticWallpaperService =
        StaticWallpaperService()

    private let logger = Logger(
        subsystem:
            Bundle.main.bundleIdentifier
            ?? "MacLiveWallpaper",
        category: "DisplayWallpaper"
    )
    
    // MARK: - Initialization

    init(display: DisplayInfo) {

        self.displayID = display.id

        self.windowManager =
            WallpaperWindowManager()

        self.playbackController =
            VideoPlayerController()
    }
    func setStaticFallback(
        from url: URL,
        on screen: NSScreen
    ) async {

        do {

            try await staticWallpaperService
                .setFallbackWallpaper(
                    from: url,
                    on: screen
                )

            logger.info(
                "Static fallback applied to display \(self.displayID)."
            )

        } catch {

            logger.error(
                "Failed to apply static fallback: \(error.localizedDescription)"
            )
        }
    }
    func showStaticFallback(
        from url: URL,
        on screen: NSScreen
    ) async {

        playbackController.pause()

        windowManager.hideWallpaper()

        await setStaticFallback(
            from: url,
            on: screen
        )
    }

    // MARK: - Show

    func show(on screen: NSScreen) {

        guard let player = playbackController.player else {
            return
        }

        
        windowManager.showWallpaper(
            player: player,
            scalingMode: .fill
        )
    }

    
    // MARK: - Hide

    func hide() {

        windowManager.hideWallpaper()

        playbackController.unloadVideo()
    }

    // MARK: - Load Video

    func loadVideo(
        from url: URL
    ) async throws {

        try await playbackController.loadVideo(
            from: url
        )
    }

    // MARK: - Play

    func play() {

        playbackController.play()
    }

    // MARK: - Pause

    func pause() {

        playbackController.pause()
    }
    
}
