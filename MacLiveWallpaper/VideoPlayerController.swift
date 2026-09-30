//
//  VideoPlayerController.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//

//
//  VideoPlayerController.swift
//  MacLiveWallpaper
//
//  Stage 4 — Video Playback Controller
//

import Foundation
import Combine
import AVFoundation
import OSLog

@MainActor
final class VideoPlayerController: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var player: AVPlayer?
    @Published private(set) var isPlaying = false
    @Published private(set) var hasLoadedVideo = false
    @Published private(set) var playbackError: String?

    // MARK: - Private Properties

    private var securityScopedURL: URL?

    private var endObserver: NSObjectProtocol?
    private var failureObserver: NSObjectProtocol?

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "MacLiveWallpaper",
        category: "VideoPlayback"
    )

    // MARK: - Initialization

    init() {
        logger.debug("VideoPlayerController initialized")
    }

    deinit {
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        if let observer = failureObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Load Video

    func loadVideo(from url: URL) {

        logger.info(
            "Loading video: \(url.lastPathComponent, privacy: .public)"
        )

        // Remove previously loaded video.
        unloadVideo()

        playbackError = nil

        // Start security-scoped access.
        if url.startAccessingSecurityScopedResource() {
            securityScopedURL = url

            logger.debug("Security-scoped access granted")
        } else {
            logger.warning("Security-scoped access was not granted")
        }

        // Create player.
        let newPlayer = AVPlayer(url: url)

        // Pause when reaching the end.
        newPlayer.actionAtItemEnd = .pause

        player = newPlayer
        hasLoadedVideo = true
        isPlaying = false

        // Install playback notifications.
        installObservers(for: newPlayer.currentItem)

        logger.info("Video loaded successfully")
    }

    // MARK: - Play

    func play() {

        guard let player else {
            logger.warning("Play requested but no player exists")
            return
        }

        guard player.currentItem != nil else {
            logger.warning("Play requested but player has no item")
            return
        }

        playbackError = nil

        player.play()

        isPlaying = true

        logger.debug("Playback started")
    }

    // MARK: - Pause

    func pause() {

        guard let player else {
            logger.warning("Pause requested but no player exists")
            return
        }

        player.pause()

        isPlaying = false

        logger.debug("Playback paused")
    }

    // MARK: - Stop

    func stop() {

        guard let player else {
            logger.warning("Stop requested but no player exists")
            return
        }

        player.pause()

        player.seek(
            to: .zero,
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )

        isPlaying = false

        logger.debug("Playback stopped")
    }

    // MARK: - Restart

    func restart() {

        guard let player else {
            logger.warning("Restart requested but no player exists")
            return
        }

        playbackError = nil

        player.seek(
            to: .zero,
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )

        player.play()

        isPlaying = true

        logger.debug("Playback restarted")
    }

    // MARK: - Unload

    func unloadVideo() {

        logger.debug("Unloading current video")

        removeObservers()

        player?.pause()

        player = nil

        hasLoadedVideo = false
        isPlaying = false
        playbackError = nil

        // Stop security-scoped access.
        if let url = securityScopedURL {

            url.stopAccessingSecurityScopedResource()

            securityScopedURL = nil

            logger.debug("Security-scoped access stopped")
        }
    }

    // MARK: - Notification Observers

    private func installObservers(for item: AVPlayerItem?) {

        guard let item else {

            logger.warning(
                "Cannot install observers because AVPlayerItem is nil"
            )

            return
        }

        removeObservers()

        // ---------------------------------------------------------
        // Video reached the end
        // ---------------------------------------------------------

        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in

            Task { @MainActor [weak self] in
                self?.handleVideoFinished()
            }
        }

        // ---------------------------------------------------------
        // Playback failed
        // ---------------------------------------------------------

        failureObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.failedToPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] notification in

            let error = notification.userInfo?[
                AVPlayerItemFailedToPlayToEndTimeErrorKey
            ] as? Error

            Task { @MainActor [weak self] in
                self?.handlePlaybackFailure(error)
            }
        }
    }

    // MARK: - Remove Observers

    private func removeObservers() {

        if let observer = endObserver {

            NotificationCenter.default.removeObserver(observer)

            endObserver = nil
        }

        if let observer = failureObserver {

            NotificationCenter.default.removeObserver(observer)

            failureObserver = nil
        }
    }

    // MARK: - Handle Video Finished

    private func handleVideoFinished() {

        guard let player else {
            return
        }

        logger.debug("Video reached the end")

        // ---------------------------------------------------------
        // Stage 4 basic looping
        //
        // Stage 8 will replace this with:
        // AVQueuePlayer + AVPlayerLooper
        //
        // for true seamless looping.
        // ---------------------------------------------------------

        player.seek(
            to: .zero,
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )

        player.play()

        isPlaying = true

        logger.debug("Video loop restarted")
    }

    // MARK: - Handle Playback Failure

    private func handlePlaybackFailure(_ error: Error?) {

        isPlaying = false

        if let error {

            playbackError = error.localizedDescription

            logger.error(
                "Video playback failed: \(error.localizedDescription, privacy: .public)"
            )

        } else {

            playbackError = "The video could not be played."

            logger.error(
                "Video playback failed with an unknown error"
            )
        }
    }
}
