//import Foundation
//import AVFoundation
//import Combine
//import OSLog
//
//
//@MainActor
//final class VideoPlayerController: ObservableObject {
//
//    // MARK: - Published State
//
//    @Published private(set) var player: AVPlayer?
//
//    @Published private(set) var isPlaying = false
//
//    @Published private(set) var hasLoadedVideo = false
//
//    @Published private(set) var playbackError: String?
//
//
//    // MARK: - Private State
//
//    private var playerLooper: AVPlayerLooper?
//
//    private var securityScopedURL: URL?
//
//    private var notificationObservers: [
//        NSObjectProtocol
//    ] = []
//
//
//    // MARK: - Logger
//
//    private let logger = Logger(
//        subsystem:
//            Bundle.main.bundleIdentifier
//            ?? "MacLiveWallpaper",
//        category: "VideoPlayback"
//    )
//
//
//    // MARK: - Load Video
//
//    func loadVideo(
//        from url: URL
//    ) async throws {
//
//        // Remove the previous video first.
//        unloadVideo()
//
//        playbackError = nil
//
//        logger.info(
//            "Loading video: \(url.lastPathComponent)"
//        )
//
//
//        // ---------------------------------------------------------
//        // Start security-scoped access
//        // ---------------------------------------------------------
//
//        let accessGranted =
//            url.startAccessingSecurityScopedResource()
//
//        guard accessGranted else {
//
//            logger.error(
//                "Security-scoped access denied: \(url.path)"
//            )
//
//            throw VideoPlaybackError
//                .securityAccessDenied
//        }
//
//        securityScopedURL = url
//
//
//        do {
//
//            // -----------------------------------------------------
//            // Create AVURLAsset
//            // -----------------------------------------------------
//
//            let asset = AVURLAsset(
//                url: url
//            )
//
//
//            // -----------------------------------------------------
//            // Load duration BEFORE creating AVPlayerLooper.
//            // -----------------------------------------------------
//
//            let duration =
//                try await asset.load(.duration)
//
//            guard duration.isNumeric,
//                  duration.seconds > 0 else {
//
//                throw VideoPlaybackError
//                    .invalidDuration
//            }
//
//
//            // -----------------------------------------------------
//            // Create player item
//            // -----------------------------------------------------
//
//            let playerItem =
//                AVPlayerItem(
//                    asset: asset
//                )
//
//
//            // -----------------------------------------------------
//            // Create queue player
//            // -----------------------------------------------------
//
//            let queuePlayer =
//                AVQueuePlayer(
//                    items: [
//                        playerItem
//                    ]
//                )
//
//            queuePlayer.actionAtItemEnd = .pause
//
//
//            // -----------------------------------------------------
//            // Create the automatic looper.
//            // -----------------------------------------------------
//
//            let looper =
//                AVPlayerLooper(
//                    player: queuePlayer,
//                    templateItem: playerItem
//                )
//
//
//            // -----------------------------------------------------
//            // Store everything.
//            // -----------------------------------------------------
//
//            self.player =
//                queuePlayer
//
//            self.playerLooper =
//                looper
//
//            self.hasLoadedVideo = true
//
//            self.isPlaying = false
//
//
//            // -----------------------------------------------------
//            // Install playback observers.
//            // -----------------------------------------------------
//
//            installObservers(
//                for: queuePlayer,
//                playerItem: playerItem
//            )
//
//
//            logger.info(
//                "Video loaded successfully: \(url.lastPathComponent)"
//            )
//
//            logger.info(
//                "Automatic looping enabled."
//            )
//
//        } catch {
//
//            logger.error(
//                "Failed to load video: \(error.localizedDescription)"
//            )
//
//            unloadVideo()
//
//            throw error
//        }
//    }
//
//
//    // MARK: - Play
//
//    
//    func play() {
//
//        guard let player else {
//            return
//        }
//
//        guard hasLoadedVideo else {
//            return
//        }
//
//        playbackError = nil
//
//        player.play()
//
//        isPlaying = true
//
//        logger.info(
//            "Playback started."
//        )
//    }
//
//
//    // MARK: - Pause
//
//    func pause() {
//
//        guard let player else {
//            return
//        }
//
//        player.pause()
//
//        isPlaying = false
//
//        logger.info(
//            "Playback paused."
//        )
//    }
//
//
//    // MARK: - Stop
//
//    func stop() {
//
//        guard let player else {
//            return
//        }
//
//        player.pause()
//
//        player.seek(
//            to: .zero
//        )
//
//        isPlaying = false
//
//        logger.info(
//            "Playback stopped."
//        )
//    }
//
//
//    // MARK: - Restart
//
//    func restart() {
//
//        guard let player else {
//            return
//        }
//
//        playbackError = nil
//
//        player.seek(
//            to: .zero
//        ) { [weak self] finished in
//
//            guard finished,
//                  let self else {
//                return
//            }
//
//            Task { @MainActor [weak self] in
//
//                guard let self else {
//                    return
//                }
//
//                self.player?.play()
//
//                self.isPlaying = true
//
//                self.logger.info(
//                    "Playback restarted."
//                )
//            }
//        }
//    }
//
//
//    // MARK: - Unload
//
//    func unloadVideo() {
//
//        removeObservers()
//
//        player?.pause()
//
//        playerLooper?.disableLooping()
//
//        playerLooper = nil
//
//        player = nil
//
//        hasLoadedVideo = false
//
//        isPlaying = false
//
//        playbackError = nil
//
//
//        // ---------------------------------------------------------
//        // Stop security-scoped access.
//        // ---------------------------------------------------------
//
//        if let securityScopedURL {
//
//            securityScopedURL
//                .stopAccessingSecurityScopedResource()
//
//            self.securityScopedURL = nil
//        }
//
//
//        logger.info(
//            "Video unloaded."
//        )
//    }
//
//
//    // MARK: - Observers
//
//    private func installObservers(
//        for player: AVQueuePlayer,
//        playerItem: AVPlayerItem
//    ) {
//
//        removeObservers()
//
//
//        // ---------------------------------------------------------
//        // Playback failure
//        // ---------------------------------------------------------
//
//        let failureObserver =
//            NotificationCenter.default.addObserver(
//                forName:
//                    AVPlayerItem
//                        .failedToPlayToEndTimeNotification,
//                object: playerItem,
//                queue: .main
//            ) { [weak self] notification in
//
//                let error =
//                    notification.userInfo?[
//                        AVPlayerItemFailedToPlayToEndTimeErrorKey
//                    ] as? Error
//
//                Task { @MainActor [weak self] in
//
//                    guard let self else {
//                        return
//                    }
//
//                    self.handlePlaybackFailure(
//                        error
//                    )
//                }
//            }
//
//
//        // ---------------------------------------------------------
//        // Player item status failure
//        // ---------------------------------------------------------
//
//        let statusObserver =
//            NotificationCenter.default.addObserver(
//                forName:
//                    AVPlayerItem
//                        .newErrorLogEntryNotification,
//                object: playerItem,
//                queue: .main
//            ) { [weak self] _ in
//
//                Task { @MainActor [weak self] in
//
//                    guard let self else {
//                        return
//                    }
//
//                    self.logger.warning(
//                        "AVPlayerItem reported a new error-log entry."
//                    )
//                }
//            }
//
//
//        notificationObservers = [
//            failureObserver,
//            statusObserver
//        ]
//
//
//        logger.info(
//            "Playback observers installed."
//        )
//    }
//
//
//    private func removeObservers() {
//
//        for observer in notificationObservers {
//
//            NotificationCenter.default
//                .removeObserver(observer)
//        }
//
//        notificationObservers.removeAll()
//    }
//
//
//    // MARK: - Playback Failure
//
//    private func handlePlaybackFailure(
//        _ error: Error?
//    ) {
//
//        isPlaying = false
//
//        playbackError =
//            error?.localizedDescription
//            ?? "The video failed during playback."
//
//        logger.error(
//            "Playback failed: \(self.playbackError ?? "Unknown error")"
//        )
//    }
//
//
//    // MARK: - Deinitialization
//
//    deinit {
//
//        for observer in notificationObservers {
//
//            NotificationCenter.default
//                .removeObserver(observer)
//        }
//    }
//}
//
//
//// MARK: - Playback Errors
//
//enum VideoPlaybackError:
//    LocalizedError {
//
//    case securityAccessDenied
//
//    case invalidDuration
//
//
//    var errorDescription: String? {
//
//        switch self {
//
//        case .securityAccessDenied:
//
//            return
//                "macOS did not grant access to the selected video."
//
//        case .invalidDuration:
//
//            return
//                "The selected video has an invalid or zero duration."
//        }
//    }
//}


//
//  VideoPlayerController.swift
//  MacLiveWallpaper
//
//  Handles video loading, playback, looping,
//  security-scoped access, and playback errors.
//

import Foundation
import AVFoundation
import Combine
import OSLog


// ================================================================
// MARK: - Video Player Controller
// ================================================================

@MainActor
final class VideoPlayerController: ObservableObject {

    // ============================================================
    // MARK: Published State
    // ============================================================

    @Published private(set) var player: AVPlayer?

    @Published private(set) var isPlaying = false

    @Published private(set) var hasLoadedVideo = false

    @Published private(set) var playbackError: String?


    // ============================================================
    // MARK: Private State
    // ============================================================

    private var securityScopedURL: URL?

    private var notificationObservers: [
        NSObjectProtocol
    ] = []


    // ============================================================
    // MARK: Logger
    // ============================================================

    private let logger = Logger(
        subsystem:
            Bundle.main.bundleIdentifier
            ?? "MacLiveWallpaper",
        category:
            "VideoPlayback"
    )


    // ============================================================
    // MARK: Load Video
    // ============================================================

    func loadVideo(
        from url: URL
    ) async throws {

        // --------------------------------------------------------
        // Remove any previous video first.
        // --------------------------------------------------------

        unloadVideo()

        playbackError = nil

        logger.info(
            "Loading video: \(url.lastPathComponent)"
        )


        // --------------------------------------------------------
        // Security-scoped access
        // --------------------------------------------------------

        let accessGranted =
            url.startAccessingSecurityScopedResource()

        guard accessGranted else {

            logger.error(
                "Security-scoped access denied: \(url.path)"
            )

            throw VideoPlaybackError
                .securityAccessDenied
        }

        securityScopedURL = url


        do {

            // ----------------------------------------------------
            // Create AVURLAsset
            // ----------------------------------------------------

            let asset =
                AVURLAsset(
                    url: url
                )


            // ----------------------------------------------------
            // Load duration
            // ----------------------------------------------------

            let duration =
                try await asset.load(
                    .duration
                )

            guard duration.isNumeric,
                  duration.seconds > 0
            else {

                throw VideoPlaybackError
                    .invalidDuration
            }


            // ----------------------------------------------------
            // Create AVPlayerItem
            // ----------------------------------------------------

            let playerItem =
                AVPlayerItem(
                    asset: asset
                )


            // ----------------------------------------------------
            // Create ONE normal AVPlayer.
            //
            // IMPORTANT:
            // We intentionally do NOT use:
            //
            // AVQueuePlayer
            // AVPlayerLooper
            //
            // Looping is handled by the end notification below.
            // ----------------------------------------------------

            let newPlayer =
                AVPlayer(
                    playerItem: playerItem
                )

            newPlayer.actionAtItemEnd =
                .pause


            // ----------------------------------------------------
            // Store player
            // ----------------------------------------------------

            self.player =
                newPlayer

            self.hasLoadedVideo =
                true

            self.isPlaying =
                false


            // ----------------------------------------------------
            // Install observers
            // ----------------------------------------------------

            installObservers(
                for: newPlayer,
                playerItem: playerItem
            )


            logger.info(
                "Video loaded successfully: \(url.lastPathComponent)"
            )

            logger.info(
                "Notification-based infinite looping enabled."
            )

        } catch {

            logger.error(
                "Failed to load video: \(error.localizedDescription)"
            )

            unloadVideo()

            throw error
        }
    }


    // ============================================================
    // MARK: Play
    // ============================================================

    func play() {

        guard let player else {
            logger.warning(
                "Play requested but no player exists."
            )
            return
        }

        guard hasLoadedVideo else {
            logger.warning(
                "Play requested but no video is loaded."
            )
            return
        }

        playbackError = nil

        player.play()

        isPlaying = true

        logger.info(
            "Playback started."
        )
    }


    // ============================================================
    // MARK: Pause
    // ============================================================

    func pause() {

        guard let player else {
            return
        }

        player.pause()

        isPlaying = false

        logger.info(
            "Playback paused."
        )
    }


    // ============================================================
    // MARK: Stop
    // ============================================================

    func stop() {

        guard let player else {
            return
        }

        player.pause()

        player.seek(
            to: .zero
        )

        isPlaying = false

        logger.info(
            "Playback stopped."
        )
    }


    // ============================================================
    // MARK: Restart
    // ============================================================

    func restart() {

        guard let player,
              hasLoadedVideo
        else {
            return
        }

        playbackError = nil

        // The desired final state is playing.
        isPlaying = true

        player.seek(
            to: .zero,
            toleranceBefore: .zero,
            toleranceAfter: .zero
        ) { finished in

            guard finished else {
                return
            }

            player.play()
        }

        logger.info(
            "Playback restarted."
        )
    }


    // ============================================================
    // MARK: Unload
    // ============================================================

    func unloadVideo() {

        // --------------------------------------------------------
        // Remove notification observers FIRST.
        // --------------------------------------------------------

        removeObservers()


        // --------------------------------------------------------
        // Stop playback.
        // --------------------------------------------------------

        player?.pause()


        // --------------------------------------------------------
        // Release player.
        // --------------------------------------------------------

        player = nil


        // --------------------------------------------------------
        // Reset state.
        // --------------------------------------------------------

        hasLoadedVideo = false

        isPlaying = false

        playbackError = nil


        // --------------------------------------------------------
        // Stop security-scoped access.
        // --------------------------------------------------------

        if let url =
            securityScopedURL {

            url.stopAccessingSecurityScopedResource()

            securityScopedURL = nil
        }


        logger.info(
            "Video unloaded."
        )
    }


    // ============================================================
    // MARK: Notification Observers
    // ============================================================

    private func installObservers(
        for player: AVPlayer,
        playerItem: AVPlayerItem
    ) {

        // --------------------------------------------------------
        // Remove previous observers.
        // --------------------------------------------------------

        removeObservers()


        // ========================================================
        // VIDEO END — INFINITE LOOP
        // ========================================================

        let loopObserver =
            NotificationCenter.default.addObserver(
                forName:
                    AVPlayerItem
                    .didPlayToEndTimeNotification,

                object:
                    playerItem,

                queue:
                    .main

            ) { [weak self] _ in

                Task { @MainActor [weak self] in

                    guard let self else {
                        return
                    }

                    self.handleVideoFinished(
                        player: player,
                        item: playerItem
                    )
                }
            }


        // ========================================================
        // PLAYBACK FAILURE
        // ========================================================

        let failureObserver =
            NotificationCenter.default.addObserver(
                forName:
                    AVPlayerItem
                    .failedToPlayToEndTimeNotification,

                object:
                    playerItem,

                queue:
                    .main

            ) { [weak self] notification in

                let error =
                    notification.userInfo?[
                        AVPlayerItemFailedToPlayToEndTimeErrorKey
                    ] as? Error

                Task { @MainActor [weak self] in

                    guard let self else {
                        return
                    }

                    self.handlePlaybackFailure(
                        error
                    )
                }
            }


        // ========================================================
        // AVPLAYER ERROR LOG
        // ========================================================

        let errorLogObserver =
            NotificationCenter.default.addObserver(
                forName:
                    AVPlayerItem
                    .newErrorLogEntryNotification,

                object:
                    playerItem,

                queue:
                    .main

            ) { [weak self] _ in

                Task { @MainActor [weak self] in

                    guard let self else {
                        return
                    }

                    self.logger.warning(
                        "AVPlayerItem reported a new error-log entry."
                    )
                }
            }


        // --------------------------------------------------------
        // Store all observers.
        // --------------------------------------------------------

        notificationObservers = [

            loopObserver,

            failureObserver,

            errorLogObserver
        ]


        logger.info(
            "Playback observers installed."
        )
    }


    // ============================================================
    // MARK: Video Finished
    // ============================================================

    private func handleVideoFinished(
        player: AVPlayer,
        item: AVPlayerItem
    ) {

        // --------------------------------------------------------
        // Make sure this is still our active player.
        // --------------------------------------------------------

        guard hasLoadedVideo else {
            return
        }

        guard self.player === player else {
            return
        }

        guard player.currentItem === item else {
            return
        }


        logger.info(
            "Video reached the end. Looping to beginning."
        )


        // --------------------------------------------------------
        // Remember whether the player was playing.
        //
        // Normally this is TRUE because the notification fires
        // after normal playback reaches the end.
        // --------------------------------------------------------

        let shouldPlay =
            isPlaying


        // --------------------------------------------------------
        // Seek to the exact beginning.
        //
        // Zero tolerance helps avoid starting from a nearby frame.
        // --------------------------------------------------------

        player.seek(
            to: .zero,
            toleranceBefore: .zero,
            toleranceAfter: .zero
        ) { finished in

            guard finished else {
                return
            }


            // ----------------------------------------------------
            // IMPORTANT:
            //
            // Do NOT capture self here.
            //
            // This avoids the Swift 6 weak/strong capture warning
            // and avoids the EXC_BAD_ACCESS problem caused by
            // complicated nested captures.
            // ----------------------------------------------------

            if shouldPlay {

                player.play()

            } else {

                player.pause()
            }
        }
    }


    // ============================================================
    // MARK: Remove Observers
    // ============================================================

    private func removeObservers() {

        for observer in
            notificationObservers {

            NotificationCenter.default
                .removeObserver(
                    observer
                )
        }

        notificationObservers.removeAll()
    }


    // ============================================================
    // MARK: Playback Failure
    // ============================================================

    private func handlePlaybackFailure(
        _ error: Error?
    ) {

        isPlaying = false

        playbackError =
            error?.localizedDescription
            ??
            "The video failed during playback."


        logger.error(
            "Playback failed: \(self.playbackError ?? "Unknown error")"
        )
    }


    // ============================================================
    // MARK: Deinitialization
    // ============================================================

    deinit {

        for observer in
            notificationObservers {

            NotificationCenter.default
                .removeObserver(
                    observer
                )
        }
    }
}


// =================================================================
// MARK: - Playback Errors
// =================================================================

enum VideoPlaybackError:
    LocalizedError {

    case securityAccessDenied

    case invalidDuration


    var errorDescription: String? {

        switch self {

        case .securityAccessDenied:

            return
                "macOS did not grant access to the selected video."


        case .invalidDuration:

            return
                "The selected video has an invalid or zero duration."
        }
    }
}
