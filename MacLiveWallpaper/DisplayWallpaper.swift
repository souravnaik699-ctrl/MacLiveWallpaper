//
//  DisplayWallpaper.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//

import AppKit
import Foundation

@MainActor
final class DisplayWallpaper {

    // MARK: - Properties

    let displayID: CGDirectDisplayID

    let windowManager: WallpaperWindowManager

    let playbackController: VideoPlayerController

    // MARK: - Initialization

    init(display: DisplayInfo) {

        self.displayID = display.id

        self.windowManager =
            WallpaperWindowManager()

        self.playbackController =
            VideoPlayerController()
    }

    // MARK: - Show

    func show(on screen: NSScreen) {

        guard let player = playbackController.player else {
            return
        }

        windowManager.show(
            on: screen,
            player: player
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
