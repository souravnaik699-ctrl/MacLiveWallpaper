//
//
//import AppKit
//import SwiftUI
//import AVFoundation
//import CoreGraphics
//import OSLog

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
    private let targetDisplayID: CGDirectDisplayID

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

  
    init(displayID: CGDirectDisplayID) {
        self.targetDisplayID = displayID
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

        // Find ONLY the display this manager owns.
        guard let screen = NSScreen.screens.first(
            where: {
                displayID(for: $0) == targetDisplayID
            }
        ) else {

            logger.warning(
                "Target display \(self.targetDisplayID) is currently unavailable."
            )

            hideAllWindows()

            return
        }

        /*
         Pause only this display's player.

         Each DisplayWallpaper has its own VideoPlayerController,
         so this does not pause another display's player.
         */
        player.pause()

        /*
         Hide the existing window for this display.
         */
        hideAllWindows()

        logger.info(
            "Creating/reusing wallpaper window for display: \(screen.localizedName)"
        )

        let window: NSWindow

        if let existingWindow = windows[targetDisplayID] {

            window = existingWindow

            window.setFrame(
                screen.frame,
                display: false
            )

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

            windows[targetDisplayID] = window

            logger.info(
                "Created wallpaper window for display: \(screen.localizedName)"
            )
        }

        window.orderFrontRegardless()

        /*
         Give AppKit / SwiftUI time to finish creating
         the video layer before playback starts.
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
                    "Wallpaper playback started on display \(self.targetDisplayID)."
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
