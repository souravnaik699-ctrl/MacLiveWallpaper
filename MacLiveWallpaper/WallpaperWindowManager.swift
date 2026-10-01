//
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
//    // MARK: - Playback State
//
//    private struct PlaybackSnapshot {
//        let time: CMTime
//        let wasPlaying: Bool
//    }
//
//    // MARK: - Properties
//
//    private var windows: [CGDirectDisplayID: NSWindow] = [:]
//
//    private var currentPlayer: AVPlayer?
//
//    private var scalingMode: VideoScalingMode = .fill
//
//    private var wallpaperIsVisible = false
//
//    // Display notification observer
//    private var displayNotificationTask: Task<Void, Never>?
//
//    // Delayed display rebuild
//    private var displayRebuildTask: Task<Void, Never>?
//
//    // Sleep observer
//    private var sleepTask: Task<Void, Never>?
//
//    // Wake observer
//    private var wakeTask: Task<Void, Never>?
//
//    // Playback state captured immediately before sleep.
//    //
//    // This is important because after the Mac wakes,
//    // AVPlayer may already report itself as paused.
//    private var playbackSnapshotBeforeSleep: PlaybackSnapshot?
//
//    // MARK: - Logger
//
//    private let logger = Logger(
//        subsystem: Bundle.main.bundleIdentifier
//            ?? "MacLiveWallpaper",
//        category: "WallpaperEngine"
//    )
//
//    // MARK: - Initialization
//
//    init() {
//        startScreenChangeMonitoring()
//        startSleepMonitoring()
//        startWakeMonitoring()
//    }
//
//    deinit {
//        displayNotificationTask?.cancel()
//        displayRebuildTask?.cancel()
//        sleepTask?.cancel()
//        wakeTask?.cancel()
//    }
//
//    // MARK: - Show Wallpaper
//
//    func showWallpaper(
//        player: AVPlayer,
//        scalingMode: VideoScalingMode
//    ) {
//        self.logger.info(
//            "Starting wallpaper engine."
//        )
//
//        self.currentPlayer = player
//        self.scalingMode = scalingMode
//        self.wallpaperIsVisible = true
//
//        // Any previous sleep snapshot is no longer needed.
//        self.playbackSnapshotBeforeSleep = nil
//
//        self.rebuildWindows(
//            preservingPlayback: false,
//            playbackSnapshotOverride: nil
//        )
//    }
//
//    // MARK: - Hide Wallpaper
//
//    func hideWallpaper() {
//        self.logger.info(
//            "Stopping wallpaper engine."
//        )
//
//        self.wallpaperIsVisible = false
//        self.currentPlayer = nil
//
//        self.playbackSnapshotBeforeSleep = nil
//
//        self.displayRebuildTask?.cancel()
//        self.displayRebuildTask = nil
//
//        self.closeAllWindows()
//    }
//
//    // MARK: - Rebuild Wallpaper
//
//    private func rebuildWindows(
//        preservingPlayback: Bool,
//        playbackSnapshotOverride: PlaybackSnapshot?
//    ) {
//        guard self.wallpaperIsVisible,
//              let player = self.currentPlayer
//        else {
//            return
//        }
//
//        let snapshot: PlaybackSnapshot?
//
//        if let playbackSnapshotOverride {
//            snapshot = playbackSnapshotOverride
//        } else if preservingPlayback {
//            snapshot = self.capturePlaybackState(
//                from: player
//            )
//        } else {
//            snapshot = nil
//        }
//
//        // Pause the player before destroying the visual layers.
//        //
//        // IMPORTANT:
//        // We keep the same AVPlayer alive.
//        player.pause()
//
//        // Remove existing wallpaper windows.
//        self.closeAllWindows()
//
//        let screens = NSScreen.screens
//
//        guard !screens.isEmpty else {
//            self.logger.error(
//                "No screens available while rebuilding wallpaper."
//            )
//            return
//        }
//
//        self.logger.info(
//            "Rebuilding wallpaper for \(screens.count) display(s)."
//        )
//
//        // Create a wallpaper window for every display.
//        for screen in screens {
//
//            let window = self.createWallpaperWindow(
//                for: screen,
//                player: player,
//                scalingMode: self.scalingMode
//            )
//
//            let id = self.displayID(
//                for: screen
//            )
//
//            self.windows[id] = window
//
//            // Make sure the wallpaper window is visible.
//            window.orderFrontRegardless()
//
//            self.logger.info(
//                "Wallpaper window bound to display: \(screen.localizedName)"
//            )
//        }
//
//        // Allow AppKit / SwiftUI / AVPlayerLayer
//        // to finish rebuilding their hierarchy.
//        Task { @MainActor [weak self, weak player] in
//
//            await Task.yield()
//            await Task.yield()
//
//            guard !Task.isCancelled else {
//                return
//            }
//
//            guard let self,
//                  self.wallpaperIsVisible,
//                  let player
//            else {
//                return
//            }
//
//            CATransaction.flush()
//
//            self.restorePlayback(
//                snapshot,
//                to: player
//            )
//        }
//    }
//
//    // MARK: - Capture Playback State
//
//    private func capturePlaybackState(
//        from player: AVPlayer
//    ) -> PlaybackSnapshot {
//
//        let currentTime = player.currentTime()
//
//        let validTime: CMTime
//
//        if currentTime.isNumeric {
//            validTime = currentTime
//        } else {
//            validTime = .zero
//        }
//
//        let wasPlaying =
//            player.timeControlStatus == .playing
//            ||
//            player.timeControlStatus
//                == .waitingToPlayAtSpecifiedRate
//
//        return PlaybackSnapshot(
//            time: validTime,
//            wasPlaying: wasPlaying
//        )
//    }
//
//    // MARK: - Restore Playback
//
//    private func restorePlayback(
//        _ snapshot: PlaybackSnapshot?,
//        to player: AVPlayer
//    ) {
//        guard let snapshot else {
//
//            self.logger.info(
//                "Wallpaper rebuilt. No playback restoration required."
//            )
//
//            return
//        }
//
//        guard let item = player.currentItem else {
//
//            self.logger.error(
//                "Cannot restore playback because AVPlayer has no current item."
//            )
//
//            return
//        }
//
//        var restoreTime = snapshot.time
//
//        // Prevent seeking beyond the current item duration.
//        let duration = item.duration
//
//        if duration.isNumeric,
//           duration.seconds > 0,
//           restoreTime.isNumeric {
//
//            let maximumTime = max(
//                0,
//                duration.seconds - 0.05
//            )
//
//            if restoreTime.seconds > maximumTime {
//
//                restoreTime = CMTime(
//                    seconds: maximumTime,
//                    preferredTimescale: 600
//                )
//            }
//        }
//
//        let shouldResumePlaying = snapshot.wasPlaying
//
//        player.seek(
//            to: restoreTime,
//            toleranceBefore: .zero,
//            toleranceAfter: .zero
//        ) { [weak player] finished in
//
//            guard let player else {
//                return
//            }
//
//            Task { @MainActor in
//
//                guard finished else {
//
//                    if shouldResumePlaying {
//                        player.play()
//                    } else {
//                        player.pause()
//                    }
//
//                    return
//                }
//
//                if shouldResumePlaying {
//                    player.play()
//                } else {
//                    player.pause()
//                }
//            }
//        }
//    }
//
//    // MARK: - Create Wallpaper Window
//
//    private func createWallpaperWindow(
//        for screen: NSScreen,
//        player: AVPlayer,
//        scalingMode: VideoScalingMode
//    ) -> NSWindow {
//
//        let window = NSWindow(
//            contentRect: screen.frame,
//            styleMask: [.borderless],
//            backing: .buffered,
//            defer: false,
//            screen: screen
//        )
//
//        window.isOpaque = true
//        window.backgroundColor = .black
//        window.hasShadow = false
//
//        // Wallpaper must never intercept mouse input.
//        window.ignoresMouseEvents = true
//        window.acceptsMouseMovedEvents = false
//
//        // Put the window at the desktop level.
//        window.level = NSWindow.Level(
//            rawValue: Int(
//                CGWindowLevelForKey(
//                    .desktopWindow
//                )
//            )
//        )
//
//        // Make the wallpaper available across Spaces.
//        window.collectionBehavior = [
//            .canJoinAllSpaces,
//            .stationary,
//            .ignoresCycle
//        ]
//
//        window.isMovable = false
//        window.isExcludedFromWindowsMenu = true
//
//        // Match the physical display frame.
//        window.setFrame(
//            screen.frame,
//            display: true
//        )
//
//        // MARK: Video View
//
//        let videoView = VideoPlayerView(
//            player: player,
//            scalingMode: scalingMode
//        )
//
//        let hostingView = NSHostingView(
//            rootView: videoView
//        )
//
//        hostingView.frame = NSRect(
//            origin: .zero,
//            size: window.contentLayoutRect.size
//        )
//
//        hostingView.autoresizingMask = [
//            .width,
//            .height
//        ]
//
//        window.contentView = hostingView
//
//        // Force layout immediately.
//        hostingView.layoutSubtreeIfNeeded()
//
//        return window
//    }
//
//    // MARK: - Sleep Monitoring
//
//    private func startSleepMonitoring() {
//
//        self.sleepTask = Task { @MainActor [weak self] in
//
//            let notifications =
//                NSWorkspace.shared.notificationCenter.notifications(
//                    named: NSWorkspace.willSleepNotification
//                )
//
//            for await _ in notifications {
//
//                guard !Task.isCancelled else {
//                    break
//                }
//
//                guard let self else {
//                    break
//                }
//
//                self.handleSystemSleep()
//            }
//        }
//    }
//
//    // MARK: - Handle System Sleep
//
//    private func handleSystemSleep() {
//
//        guard self.wallpaperIsVisible else {
//
//            self.logger.info(
//                "Mac is going to sleep, but wallpaper is not active."
//            )
//
//            return
//        }
//
//        guard let player = self.currentPlayer else {
//
//            self.logger.warning(
//                "Mac is going to sleep, but no wallpaper player exists."
//            )
//
//            return
//        }
//
//        // IMPORTANT:
//        //
//        // Capture the playback state BEFORE macOS suspends
//        // the AVPlayer.
//        self.playbackSnapshotBeforeSleep =
//            self.capturePlaybackState(
//                from: player
//            )
//
//        self.logger.info(
//            "Captured wallpaper playback state before sleep."
//        )
//    }
//
//    // MARK: - Wake Monitoring
//
//    private func startWakeMonitoring() {
//
//        self.wakeTask = Task { @MainActor [weak self] in
//
//            let notifications =
//                NSWorkspace.shared.notificationCenter.notifications(
//                    named: NSWorkspace.didWakeNotification
//                )
//
//            for await _ in notifications {
//
//                guard !Task.isCancelled else {
//                    break
//                }
//
//                guard let self else {
//                    break
//                }
//
//                self.handleSystemWake()
//            }
//        }
//    }
//
//    // MARK: - Handle System Wake
//
//    private func handleSystemWake() {
//
//        guard self.wallpaperIsVisible else {
//
//            self.logger.info(
//                "Mac woke from sleep, but wallpaper is not active."
//            )
//
//            return
//        }
//
//        guard let player = self.currentPlayer else {
//
//            self.logger.warning(
//                "Mac woke from sleep, but no wallpaper player exists."
//            )
//
//            return
//        }
//
//        self.logger.info(
//            "Mac woke from sleep. Restoring wallpaper."
//        )
//
//        // Use the state captured BEFORE sleep.
//        //
//        // Do not call capturePlaybackState() here because
//        // AVPlayer may already report itself as paused.
//        let snapshot = self.playbackSnapshotBeforeSleep
//
//        // Try twice because macOS may need a moment to
//        // recreate the display/window environment.
//        self.scheduleWakeRebuild(
//            player: player,
//            snapshot: snapshot,
//            delay: 1.0,
//            attempt: 1
//        )
//    }
//
//    // MARK: - Wake Rebuild
//
//    private func scheduleWakeRebuild(
//        player: AVPlayer,
//        snapshot: PlaybackSnapshot?,
//        delay: TimeInterval,
//        attempt: Int
//    ) {
//
//        Task { @MainActor [weak self, weak player] in
//
//            guard !Task.isCancelled else {
//                return
//            }
//
//            try? await Task.sleep(
//                nanoseconds: UInt64(
//                    delay * 1_000_000_000
//                )
//            )
//
//            guard !Task.isCancelled else {
//                return
//            }
//
//            guard let self,
//                  let player
//            else {
//                return
//            }
//
//            guard self.wallpaperIsVisible else {
//                return
//            }
//
//            guard self.currentPlayer === player else {
//                return
//            }
//
//            self.logger.info(
//                "Wake restoration attempt \(attempt)."
//            )
//
//            self.rebuildWindows(
//                preservingPlayback: true,
//                playbackSnapshotOverride: snapshot
//            )
//
//            // One additional rebuild gives macOS another
//            // opportunity to finish restoring display state.
//            if attempt < 2 {
//
//                self.scheduleWakeRebuild(
//                    player: player,
//                    snapshot: snapshot,
//                    delay: 1.5,
//                    attempt: attempt + 1
//                )
//            } else {
//
//                // The snapshot is no longer needed after
//                // the final restoration attempt.
//                self.playbackSnapshotBeforeSleep = nil
//            }
//        }
//    }
//
//    // MARK: - Screen Change Monitoring
//
//    private func startScreenChangeMonitoring() {
//
//        self.displayNotificationTask =
//            Task { @MainActor [weak self] in
//
//                let notifications =
//                    NotificationCenter.default.notifications(
//                        named:
//                            NSApplication
//                            .didChangeScreenParametersNotification
//                    )
//
//                for await _ in notifications {
//
//                    guard !Task.isCancelled else {
//                        break
//                    }
//
//                    guard let self else {
//                        break
//                    }
//
//                    guard self.wallpaperIsVisible else {
//                        continue
//                    }
//
//                    self.scheduleDisplayRebuild()
//                }
//            }
//    }
//
//    // MARK: - Schedule Display Rebuild
//
//    private func scheduleDisplayRebuild() {
//
//        // IMPORTANT:
//        //
//        // Only cancel the delayed rebuild task.
//        //
//        // Do NOT cancel displayNotificationTask,
//        // because that is the permanent screen-change observer.
//        self.displayRebuildTask?.cancel()
//
//        self.displayRebuildTask =
//            Task { @MainActor [weak self] in
//
//                // Coalesce multiple display-change notifications.
//                await Task.yield()
//
//                guard !Task.isCancelled else {
//                    return
//                }
//
//                guard let self else {
//                    return
//                }
//
//                guard self.wallpaperIsVisible else {
//                    return
//                }
//
//                self.rebuildWindows(
//                    preservingPlayback: true,
//                    playbackSnapshotOverride: nil
//                )
//            }
//    }
//
//    // MARK: - Display ID
//
//    private func displayID(
//        for screen: NSScreen
//    ) -> CGDirectDisplayID {
//
//        screen.deviceDescription[
//            NSDeviceDescriptionKey(
//                "NSScreenNumber"
//            )
//        ] as? CGDirectDisplayID
//        ?? CGMainDisplayID()
//    }
//
//    // MARK: - Close Windows
//
//    private func closeAllWindows() {
//
//        guard !self.windows.isEmpty else {
//            return
//        }
//
//        self.logger.info(
//            "Closing \(self.windows.count) wallpaper window(s)."
//        )
//
//        for window in self.windows.values {
//
//            window.orderOut(nil)
//            window.contentView = nil
//            window.close()
//        }
//
//        self.windows.removeAll()
//    }
//}


import AppKit
import SwiftUI
import AVFoundation
import CoreGraphics
import OSLog

@MainActor
final class WallpaperWindowManager {

    // MARK: - Playback Snapshot

    private struct PlaybackSnapshot {
        let time: CMTime
        let wasPlaying: Bool
    }

    // MARK: - Properties

    private var windows: [CGDirectDisplayID: NSWindow] = [:]

    private var currentPlayer: AVPlayer?

    private var scalingMode: VideoScalingMode = .fill

    private var wallpaperIsVisible = false

    // IMPORTANT:
    // Keep the notification observer task separate from
    // the rebuild task.
    private var displayNotificationTask: Task<Void, Never>?

    private var displayRebuildTask: Task<Void, Never>?

    // Sleep / wake monitoring
    private var wakeTask: Task<Void, Never>?

    // MARK: - Logger

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier
            ?? "MacLiveWallpaper",
        category: "WallpaperEngine"
    )

    // MARK: - Initialization

    init() {
        startScreenChangeMonitoring()
        startWakeMonitoring()
    }

    deinit {
        displayNotificationTask?.cancel()
        displayRebuildTask?.cancel()
        wakeTask?.cancel()
    }

    // MARK: - Show Wallpaper

    func showWallpaper(
        player: AVPlayer,
        scalingMode: VideoScalingMode
    ) {

        logger.info(
            "Starting wallpaper engine."
        )

        currentPlayer = player
        self.scalingMode = scalingMode
        wallpaperIsVisible = true

        rebuildWindows(
            preservingPlayback: false
        )
    }

    // MARK: - Hide Wallpaper

    func hideWallpaper() {

        logger.info(
            "Stopping wallpaper engine."
        )

        wallpaperIsVisible = false

        currentPlayer = nil

        displayRebuildTask?.cancel()
        displayRebuildTask = nil

        /*
         IMPORTANT:

         Do NOT call NSWindow.close() here.

         Wallpaper windows are simply hidden using orderOut().
         This avoids the NSWindow deallocation problem detected
         by Zombie Objects.
         */

        hideAllWindows()
    }

    // MARK: - Rebuild Windows

    private func rebuildWindows(
        preservingPlayback: Bool
    ) {

        guard wallpaperIsVisible,
              let player = currentPlayer
        else {
            return
        }

        let snapshot =
            preservingPlayback
            ? capturePlaybackState(
                from: player
            )
            : nil

        /*
         Pause the player before replacing the visual windows.
         */

        player.pause()

        /*
         Hide existing windows.

         We intentionally DO NOT close them.
         */

        hideAllWindows()

        let screens = NSScreen.screens

        guard !screens.isEmpty else {

            logger.error(
                "No displays detected."
            )

            return
        }

        logger.info(
            "Creating/reusing wallpaper windows for \(screens.count) display(s)."
        )

        /*
         Create or reuse one window per display.
         */

        for screen in screens {

            let displayID = displayID(
                for: screen
            )

            let window: NSWindow

            if let existingWindow = windows[displayID] {

                window = existingWindow

                /*
                 Update frame.
                 */

                window.setFrame(
                    screen.frame,
                    display: false
                )

                /*
                 Replace the SwiftUI content safely.
                 */

                setContent(
                    of: window,
                    player: player
                )

                logger.info(
                    "Reusing wallpaper window for display: \(screen.localizedName)"
                )

            } else {

                window = createWallpaperWindow(
                    for: screen,
                    player: player
                )

                windows[displayID] = window

                logger.info(
                    "Created wallpaper window for display: \(screen.localizedName)"
                )
            }

            window.orderFrontRegardless()
        }

        /*
         Remove windows for displays that are no longer connected.

         IMPORTANT:
         We only hide them here.
         We don't call close().
         */

        let connectedDisplayIDs = Set(
            screens.map {
                displayID(for: $0)
            }
        )

        for id in windows.keys {

            if !connectedDisplayIDs.contains(id) {

                windows[id]?.orderOut(nil)

                /*
                 Remove our strong reference only after the window
                 has been hidden.
                 */

                windows.removeValue(
                    forKey: id
                )
            }
        }

        /*
         Give AppKit/SwiftUI a chance to finish creating the
         player layers before restoring playback.
         */

        if let snapshot {

            Task { @MainActor [weak self, weak player] in

                guard let self,
                      let player
                else {
                    return
                }

                guard self.wallpaperIsVisible else {
                    return
                }

                guard self.currentPlayer === player else {
                    return
                }

                await Task.yield()
                await Task.yield()

                self.restorePlayback(
                    snapshot,
                    on: player
                )
            }

        } else {

            Task { @MainActor [weak self, weak player] in

                guard let self,
                      let player
                else {
                    return
                }

                guard self.wallpaperIsVisible else {
                    return
                }

                guard self.currentPlayer === player else {
                    return
                }

                await Task.yield()

                player.play()

                self.logger.info(
                    "Wallpaper playback started."
                )
            }
        }
    }

    // MARK: - Capture Playback

    private func capturePlaybackState(
        from player: AVPlayer
    ) -> PlaybackSnapshot {

        let time = player.currentTime()

        return PlaybackSnapshot(
            time: time,
            wasPlaying: player.rate > 0
        )
    }

    // MARK: - Restore Playback

    private func restorePlayback(
        _ snapshot: PlaybackSnapshot,
        on player: AVPlayer
    ) {

        guard wallpaperIsVisible else {
            return
        }

        guard currentPlayer === player else {
            return
        }

        let shouldResumePlaying =
            snapshot.wasPlaying

        let time = snapshot.time

        player.seek(
            to: time,
            toleranceBefore: .zero,
            toleranceAfter: .zero
        ) { [weak player] finished in

            guard let player else {
                return
            }

            Task { @MainActor in

                guard finished else {

                    if shouldResumePlaying {
                        player.play()
                    } else {
                        player.pause()
                    }

                    return
                }

                if shouldResumePlaying {

                    player.play()

                } else {

                    player.pause()
                }
            }
        }
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
        // Appearance
        // ---------------------------------------------------------

        window.isOpaque = true
        window.backgroundColor = .black
        window.hasShadow = false

        // ---------------------------------------------------------
        // Mouse
        // ---------------------------------------------------------

        window.ignoresMouseEvents = true
        window.acceptsMouseMovedEvents = false

        // ---------------------------------------------------------
        // Desktop Level
        // ---------------------------------------------------------

        let desktopLevel =
            CGWindowLevelForKey(
                .desktopWindow
            )

        window.level =
            NSWindow.Level(
                rawValue: Int(desktopLevel)
            )

        // ---------------------------------------------------------
        // Spaces
        // ---------------------------------------------------------

        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle
        ]

        // ---------------------------------------------------------
        // Frame
        // ---------------------------------------------------------

        window.setFrame(
            screen.frame,
            display: false
        )

        // ---------------------------------------------------------
        // Window Behavior
        // ---------------------------------------------------------

        window.isMovable = false
        window.isMovableByWindowBackground = false
        window.isExcludedFromWindowsMenu = true

        // ---------------------------------------------------------
        // SwiftUI Video Content
        // ---------------------------------------------------------

        setContent(
            of: window,
            player: player
        )

        return window
    }

    // MARK: - Set Window Content

    private func setContent(
        of window: NSWindow,
        player: AVPlayer
    ) {

        let wallpaperView = VideoPlayerView(
            player: player,
            scalingMode: scalingMode
        )

        let hostingView = NSHostingView(
            rootView: wallpaperView
        )

        hostingView.frame =
            window.contentView?.bounds
            ?? window.frame

        hostingView.autoresizingMask = [
            .width,
            .height
        ]

        /*
         Replace the content view.

         We don't close the window.
         */

        window.contentView = hostingView
    }

    // MARK: - Hide All Windows

    private func hideAllWindows() {

        guard !windows.isEmpty else {
            return
        }

        logger.info(
            "Hiding \(self.windows.count) wallpaper window(s)."
        )

        for window in windows.values {

            window.orderOut(nil)
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

        displayNotificationTask =
            Task { @MainActor [weak self] in

                let notifications =
                    NotificationCenter.default.notifications(
                        named:
                            NSApplication
                            .didChangeScreenParametersNotification
                    )

                for await _ in notifications {

                    guard !Task.isCancelled else {
                        break
                    }

                    guard let self else {
                        break
                    }

                    guard self.wallpaperIsVisible else {
                        continue
                    }

                    self.scheduleDisplayRebuild()
                }
            }
    }

    // MARK: - Schedule Display Rebuild

    private func scheduleDisplayRebuild() {

        displayRebuildTask?.cancel()

        displayRebuildTask =
            Task { @MainActor [weak self] in

                /*
                 Allow macOS to finish the display
                 configuration notification.
                 */

                await Task.yield()

                guard !Task.isCancelled,
                      let self
                else {
                    return
                }

                guard self.wallpaperIsVisible else {
                    return
                }

                self.rebuildWindows(
                    preservingPlayback: true
                )
            }
    }

    // MARK: - Wake Monitoring

    private func startWakeMonitoring() {

        wakeTask =
            Task { @MainActor [weak self] in

                let notifications =
                    NSWorkspace.shared
                        .notificationCenter
                        .notifications(
                            named:
                                NSWorkspace.didWakeNotification
                        )

                for await _ in notifications {

                    guard !Task.isCancelled else {
                        break
                    }

                    guard let self else {
                        break
                    }

                    self.handleSystemWake()
                }
            }
    }

    // MARK: - System Wake

    private func handleSystemWake() {

        guard wallpaperIsVisible else {
            return
        }

        guard currentPlayer != nil else {
            return
        }

        logger.info(
            "Mac woke from sleep. Rebuilding wallpaper windows."
        )

        Task { @MainActor [weak self] in

            guard let self else {
                return
            }

            /*
             Give WindowServer and displays time to recover.
             */

            try? await Task.sleep(
                nanoseconds: 1_000_000_000
            )

            guard !Task.isCancelled else {
                return
            }

            guard self.wallpaperIsVisible else {
                return
            }

            self.rebuildWindows(
                preservingPlayback: true
            )
        }
    }

    // MARK: - Deinitialization Safety

    func shutdown() {

        logger.info(
            "Shutting down wallpaper window manager."
        )

        wallpaperIsVisible = false

        displayNotificationTask?.cancel()
        displayNotificationTask = nil

        displayRebuildTask?.cancel()
        displayRebuildTask = nil

        wakeTask?.cancel()
        wakeTask = nil

        /*
         Hide windows instead of closing them.

         This is intentional because Zombie Objects showed
         an NSWindow deallocation problem.
         */

        hideAllWindows()

        currentPlayer = nil
    }
}
