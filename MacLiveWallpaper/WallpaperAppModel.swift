//
//  WallpaperAppModel.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 02/10/26.
//

//import SwiftUI
//import AVFoundation
//import Combine
//
//@MainActor
//final class WallpaperAppModel: ObservableObject {
//
//    // MARK: - Core Wallpaper Controllers
//
//    let playbackController: VideoPlayerController
//
//    let wallpaperManager: WallpaperWindowManager
//
//    let powerMonitor: SystemPowerMonitor
//
//    let performanceController:
//        WallpaperPerformanceController
//
//    // MARK: - Initialization
//
//    init() {
//
//        let playbackController =
//            VideoPlayerController()
//
//        let powerMonitor =
//            SystemPowerMonitor()
//
//        self.playbackController =
//            playbackController
//
//        self.powerMonitor =
//            powerMonitor
//
//        self.wallpaperManager =
//            WallpaperWindowManager(
//                displayID: CGMainDisplayID()
//            )
//        
//        self.performanceController =
//            WallpaperPerformanceController(
//                playbackController:
//                    playbackController,
//                powerMonitor:
//                    powerMonitor
//            )
//    }
//
//    // MARK: - Start Wallpaper
//
//    func startWallpaper(
//        scalingMode: VideoScalingMode
//    ) {
//
//        guard let player =
//                playbackController.player
//        else {
//            return
//        }
//
//        wallpaperManager.showWallpaper(
//            player: player,
//            scalingMode: scalingMode
//        )
//
//        playbackController.play()
//
//        performanceController.evaluate(
//            reason: "Wallpaper started"
//        )
//    }
//
//    // MARK: - Pause
//
//    func pauseWallpaper() {
//
//        playbackController.pause()
//
//        performanceController
//            .handleManualPause()
//    }
//
//    // MARK: - Resume
//
//    func resumeWallpaper() {
//
//        playbackController.play()
//
//        performanceController
//            .handleManualPlay()
//    }
//
//    // MARK: - Stop
//
//    func stopWallpaper() {
//
//        playbackController.stop()
//
//        wallpaperManager.hideWallpaper()
//    }
//
//    // MARK: - Remove Wallpaper
//
//    func removeWallpaper() {
//
//        wallpaperManager.hideWallpaper()
//
//        playbackController.pause()
//
//        performanceController
//            .handleManualPause()
//    }
//}



import SwiftUI
import AVFoundation
import Combine
import CoreGraphics

@MainActor
final class WallpaperAppModel: ObservableObject {

    // MARK: - Shared Application Coordinator

    let appCoordinator: AppCoordinator

    // MARK: - Preview Player

    /// This player is used by the main application UI for video preview.
    /// Actual wallpapers are handled by MultiDisplayWallpaperManager.
    let playbackController: VideoPlayerController

    // MARK: - Compatibility Manager

    /// Kept temporarily because the current ContentView still references it.
    /// Wallpaper rendering will gradually move to the multi-display manager.
    let wallpaperManager: WallpaperWindowManager

    // MARK: - Performance

    let powerMonitor: SystemPowerMonitor
    let performanceController: WallpaperPerformanceController

    // MARK: - Multi-Display Access

    /// The single multi-display manager owned by AppCoordinator.
    var multiDisplayWallpaperManager: MultiDisplayWallpaperManager {
        appCoordinator.multiDisplayWallpaperManager
    }

    @Published private(set) var isLiveWallpaperPlaying = false
    @Published private(set) var hasWallpaperBeenSet = false

    // MARK: - Initialization

    init(appCoordinator: AppCoordinator) {
        self.appCoordinator = appCoordinator

        let playbackController = VideoPlayerController()
        let powerMonitor = SystemPowerMonitor()

        self.playbackController = playbackController
        self.powerMonitor = powerMonitor

        // Temporary compatibility object.
        // The real wallpaper system is MultiDisplayWallpaperManager.
        self.wallpaperManager = WallpaperWindowManager(
            displayID: CGMainDisplayID()
        )

        self.performanceController = WallpaperPerformanceController(
            playbackController: playbackController,
            powerMonitor: powerMonitor
        )
    }

    // MARK: - Preview Controls

    func startWallpaper(scalingMode: VideoScalingMode) {
        guard let player = playbackController.player else {
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

    func pauseWallpaper() {
        pauseAllDisplays()
    }

    func resumeWallpaper() {
        guard hasWallpaperBeenSet else { return }
        playAllDisplays()
    }

    func stopWallpaper() {
        multiDisplayWallpaperManager.stopAll()
        playbackController.stop()
        isLiveWallpaperPlaying = false
        hasWallpaperBeenSet = false
        UserDefaults.standard.set(
            false,
            forKey: "MacLiveWallpaper.wallpaperActive"
        )
    }

    func removeWallpaper() {
        hideAllDisplays()
    }

    // MARK: - Multi-Display Wallpaper Controls

    /// Loads the selected video into every currently connected display.

    func loadWallpaperOnAllDisplays(from url: URL) async {
        await multiDisplayWallpaperManager.loadVideoOnAllDisplays(
            from: url
        )

        multiDisplayWallpaperManager.synchronizeDisplays()
    }
    /// Starts playback on every connected display.
    func playAllDisplays() {
        hasWallpaperBeenSet = true
        playbackController.play()
        multiDisplayWallpaperManager.playAll()
        isLiveWallpaperPlaying = multiDisplayWallpaperManager.isPlaying
        performanceController.handleManualPlay()
    }

    /// Pauses playback on every connected display.
    func pauseAllDisplays() {
        playbackController.pause()
        multiDisplayWallpaperManager.pauseAll()
        isLiveWallpaperPlaying = multiDisplayWallpaperManager.isPlaying
        performanceController.handleManualPause()
    }
    func hideAllDisplays() {
        multiDisplayWallpaperManager.hideAll()
        playbackController.pause()
        isLiveWallpaperPlaying = false
        hasWallpaperBeenSet = false
    }

    /// Synchronizes the wallpaper system with the currently connected displays.
    func synchronizeDisplays() {
        multiDisplayWallpaperManager.synchronizeDisplays()
    }
}
