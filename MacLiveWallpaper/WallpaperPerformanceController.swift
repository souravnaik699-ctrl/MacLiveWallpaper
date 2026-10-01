//
//  WallpaperPerformanceController.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//


import Foundation
import AppKit
import Combine
import OSLog

@MainActor
final class WallpaperPerformanceController: ObservableObject {

    @Published var mode: WallpaperPerformanceMode {
        didSet {
            UserDefaults.standard.set(
                mode.rawValue,
                forKey: Self.modeKey
            )

            evaluate(reason: "Performance mode changed")
        }
    }

    @Published var batteryThreshold: Int {
        didSet {
            let value = min(max(batteryThreshold, 5), 50)

            if batteryThreshold != value {
                batteryThreshold = value
                return
            }

            UserDefaults.standard.set(
                value,
                forKey: Self.batteryThresholdKey
            )

            evaluate(reason: "Battery threshold changed")
        }
    }

    @Published private(set) var isAutomaticallyPaused = false
    @Published private(set) var pauseReason: String?

    private weak var playbackController: VideoPlayerController?

    private let powerMonitor: SystemPowerMonitor

    private var observers: [NSObjectProtocol] = []

    private var wasPlayingBeforeAutomaticPause = false

    private static let modeKey =
        "WallpaperPerformanceMode"

    private static let batteryThresholdKey =
        "WallpaperBatteryThreshold"

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "MacLiveWallpaper",
        category: "Performance"
    )

    init(
        playbackController: VideoPlayerController,
        powerMonitor: SystemPowerMonitor
    ) {
        self.playbackController = playbackController
        self.powerMonitor = powerMonitor

        let savedMode =
            UserDefaults.standard.string(
                forKey: Self.modeKey
            )

        self.mode =
            WallpaperPerformanceMode(
                rawValue: savedMode ?? ""
            ) ?? .balanced

        let savedThreshold =
            UserDefaults.standard.object(
                forKey: Self.batteryThresholdKey
            ) as? Int

        self.batteryThreshold =
            savedThreshold ?? 20

        installObservers()

        evaluate(reason: "Performance controller started")
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public

    func evaluate(reason: String) {

        guard let playbackController else {
            return
        }

        guard playbackController.hasLoadedVideo else {
            return
        }

        if let automaticReason = automaticPauseReason() {

            if playbackController.isPlaying {
                wasPlayingBeforeAutomaticPause = true
                playbackController.pause()
            }

            isAutomaticallyPaused = true
            pauseReason = automaticReason

            logger.info(
                "Automatic pause: \(automaticReason)"
            )

            return
        }

        if isAutomaticallyPaused {

            isAutomaticallyPaused = false
            pauseReason = nil

            if wasPlayingBeforeAutomaticPause {
                playbackController.play()
                wasPlayingBeforeAutomaticPause = false

                logger.info(
                    "Automatic pause ended. Playback resumed."
                )
            }
        }

        logger.debug(
            "Performance evaluation completed: \(reason)"
        )
    }

    func handleManualPause() {
        wasPlayingBeforeAutomaticPause = false
        isAutomaticallyPaused = false
        pauseReason = nil

        logger.info(
            "Manual pause detected."
        )
    }

    func handleManualPlay() {
        if !isAutomaticallyPaused {
            playbackController?.play()
        }
    }

    // MARK: - Automatic pause decision

    private func automaticPauseReason() -> String? {

        switch mode {

        case .quality:
            return qualityModeReason()

        case .balanced:
            return balancedModeReason()

        case .batterySaver:
            return batterySaverReason()
        }
    }

    private func qualityModeReason() -> String? {

        switch powerMonitor.thermalState {

        case .critical:
            return "System thermal state is critical."

        default:
            break
        }

        return nil
    }

    private func balancedModeReason() -> String? {

        if powerMonitor.isLowPowerModeEnabled {
            return "Low Power Mode is enabled."
        }

        switch powerMonitor.thermalState {

        case .serious:
            return "System thermal state is serious."

        case .critical:
            return "System thermal state is critical."

        default:
            break
        }

        if powerMonitor.isUsingBatteryPower,
           let battery = powerMonitor.batteryPercentage,
           battery <= batteryThreshold {

            return "Battery level is \(battery)%."
        }

        return nil
    }

    private func batterySaverReason() -> String? {

        if powerMonitor.isLowPowerModeEnabled {
            return "Low Power Mode is enabled."
        }

        switch powerMonitor.thermalState {

        case .serious:
            return "System thermal state is serious."

        case .critical:
            return "System thermal state is critical."

        default:
            break
        }

        if powerMonitor.isUsingBatteryPower,
           let battery = powerMonitor.batteryPercentage,
           battery <= batteryThreshold {

            return "Battery level is \(battery)%."
        }

        return nil
    }

    // MARK: - System notifications

    private func installObservers() {

        let sleepObserver =
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: NSWorkspace.shared,
                queue: .main
            ) { [weak self] _ in

                Task { @MainActor in
                    self?.pauseForSystemEvent(
                        reason: "System is going to sleep."
                    )
                }
            }

        let screenSleepObserver =
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.screensDidSleepNotification,
                object: NSWorkspace.shared,
                queue: .main
            ) { [weak self] _ in

                Task { @MainActor in
                    self?.pauseForSystemEvent(
                        reason: "Display went to sleep."
                    )
                }
            }

        let wakeObserver =
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: NSWorkspace.shared,
                queue: .main
            ) { [weak self] _ in

                Task { @MainActor in
                    self?.evaluate(
                        reason: "System woke."
                    )
                }
            }

        let screenWakeObserver =
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.screensDidWakeNotification,
                object: NSWorkspace.shared,
                queue: .main
            ) { [weak self] _ in

                Task { @MainActor in
                    self?.evaluate(
                        reason: "Display woke."
                    )
                }
            }

        let occlusionObserver =
            NotificationCenter.default.addObserver(
                forName:
                    NSApplication.didChangeOcclusionStateNotification,
                object: NSApp,
                queue: .main
            ) { [weak self] _ in

                Task { @MainActor in
                    self?.evaluateOcclusion()
                }
            }

        observers = [
            sleepObserver,
            screenSleepObserver,
            wakeObserver,
            screenWakeObserver,
            occlusionObserver
        ]
    }

    private func pauseForSystemEvent(reason: String) {

        guard let playbackController else {
            return
        }

        if playbackController.hasLoadedVideo,
           playbackController.isPlaying {

            wasPlayingBeforeAutomaticPause = true
            playbackController.pause()
        }

        isAutomaticallyPaused = true
        pauseReason = reason

        logger.info(
            "Playback paused for system event: \(reason)"
        )
    }

    private func evaluateOcclusion() {

        guard let playbackController else {
            return
        }

        guard playbackController.hasLoadedVideo else {
            return
        }

        // The app's normal UI can remain visible while the
        // wallpaper window is behind other applications.
        //
        // Therefore we only use the application-level occlusion
        // state as an additional conservative signal.

        if NSApp.occlusionState
            .contains(.visible) {

            evaluate(
                reason: "Application became visible."
            )

        } else if playbackController.isPlaying {

            wasPlayingBeforeAutomaticPause = true
            playbackController.pause()

            isAutomaticallyPaused = true
            pauseReason = "Wallpaper application is fully occluded."

            logger.info(
                "Playback paused because the application is fully occluded."
            )
        }
    }
}
