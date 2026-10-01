//
//  WallpaperAppModel.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 02/10/26.
//

import SwiftUI
import AVFoundation
import Combine

@MainActor
final class WallpaperAppModel: ObservableObject {

    // MARK: - Core Wallpaper Controllers

    let playbackController: VideoPlayerController

    let wallpaperManager: WallpaperWindowManager

    let powerMonitor: SystemPowerMonitor

    let performanceController:
        WallpaperPerformanceController

    // MARK: - Initialization

    init() {

        let playbackController =
            VideoPlayerController()

        let powerMonitor =
            SystemPowerMonitor()

        self.playbackController =
            playbackController

        self.powerMonitor =
            powerMonitor

        self.wallpaperManager =
            WallpaperWindowManager()

        self.performanceController =
            WallpaperPerformanceController(
                playbackController:
                    playbackController,
                powerMonitor:
                    powerMonitor
            )
    }

    // MARK: - Start Wallpaper

    func startWallpaper(
        scalingMode: VideoScalingMode
    ) {

        guard let player =
                playbackController.player
        else {
            return
        }

        wallpaperManager.showWallpaper(
            player: player,
            scalingMode: scalingMode
        )

        playbackController.play()

        performanceController.evaluate(
            reason: "Wallpaper started"
        )
    }

    // MARK: - Pause

    func pauseWallpaper() {

        playbackController.pause()

        performanceController
            .handleManualPause()
    }

    // MARK: - Resume

    func resumeWallpaper() {

        playbackController.play()

        performanceController
            .handleManualPlay()
    }

    // MARK: - Stop

    func stopWallpaper() {

        playbackController.stop()

        wallpaperManager.hideWallpaper()
    }

    // MARK: - Remove Wallpaper

    func removeWallpaper() {

        wallpaperManager.hideWallpaper()

        playbackController.pause()

        performanceController
            .handleManualPause()
    }
}
