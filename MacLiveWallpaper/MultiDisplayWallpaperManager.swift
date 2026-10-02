//
//  MultiDisplayWallpaperManager.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//
//
//  MultiDisplayWallpaperManager.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//


//import AppKit
//import Foundation
//import Combine
//import OSLog
//
//@MainActor
//final class MultiDisplayWallpaperManager:
//    ObservableObject {
//
//    @Published private(set) var activeDisplayIDs:
//        Set<CGDirectDisplayID> = []
//
//    private var wallpapers:
//        [CGDirectDisplayID: DisplayWallpaper] = [:]
//
//    private let displayManager:
//        DisplayManager
//
//    private let logger = Logger(
//        subsystem:
//            Bundle.main.bundleIdentifier
//            ?? "MacLiveWallpaper",
//        category: "MultiDisplay"
//    )
//
//    init(
//        displayManager: DisplayManager
//    ) {
//
//        self.displayManager =
//            displayManager
//
//        synchronizeDisplays()
//    }
//
//    // MARK: - Display synchronization
//
//    func synchronizeDisplays() {
//
//        let currentDisplays =
//            displayManager.displays
//
//        let currentIDs =
//            Set(
//                currentDisplays.map {
//                    $0.id
//                }
//            )
//
//        let existingIDs =
//            Set(
//                wallpapers.keys
//            )
//
//        // Remove disconnected displays.
//        let removedIDs =
//            existingIDs.subtracting(
//                currentIDs
//            )
//
//        for displayID in removedIDs {
//
//            logger.info(
//                "Removing wallpaper for display \(displayID)."
//            )
//
//            wallpapers[
//                displayID
//            ]?.hide()
//
//            wallpapers[
//                displayID
//            ] = nil
//        }
//
//        // Add new displays.
//        for display in currentDisplays {
//
//            if wallpapers[display.id] == nil {
//
//                logger.info(
//                    "Creating wallpaper for display \(display.id)."
//                )
//
//                let wallpaper =
//                    DisplayWallpaper(
//                        display: display
//                    )
//
//                wallpapers[
//                    display.id
//                ] = wallpaper
//            }
//
//            updateWallpaperWindow(
//                for: display
//            )
//        }
//
//        activeDisplayIDs =
//            Set(
//                wallpapers.keys
//            )
//    }
//
//    // MARK: - Window positioning
//
//    private func updateWallpaperWindow(
//        for display: DisplayInfo
//    ) {
//
//        guard
//            let screen =
//                screen(for: display.id)
//        else {
//            return
//        }
//
//        wallpapers[
//            display.id
//        ]?.show(
//            on: screen
//        )
//    }
//
//    private func screen(
//        for displayID: CGDirectDisplayID
//    ) -> NSScreen? {
//
//        NSScreen.screens.first {
//            guard
//                let id =
//                    $0.deviceDescription[
//                        NSDeviceDescriptionKey(
//                            "NSScreenNumber"
//                        )
//                    ] as? CGDirectDisplayID
//            else {
//                return false
//            }
//
//            return id == displayID
//        }
//    }
//
//    // MARK: - Wallpaper loading
//
//    func loadVideo(
//        from url: URL,
//        on displayID: CGDirectDisplayID
//    ) async throws {
//
//        guard
//            let wallpaper =
//                wallpapers[displayID]
//        else {
//
//            throw MultiDisplayWallpaperError
//                .displayNotFound
//        }
//
//        try await wallpaper.loadVideo(
//            from: url
//        )
//    }
//
//    func loadVideoOnAllDisplays(
//        from url: URL
//    ) async {
//
//        for wallpaper in wallpapers.values {
//
//            do {
//
//                try await wallpaper.loadVideo(
//                    from: url
//                )
//
//            } catch {
//
//                logger.error(
//                    "Failed loading wallpaper on display: \(error.localizedDescription)"
//                )
//            }
//        }
//    }
//
//    // MARK: - Playback
//
//    func playAll() {
//
//        for wallpaper in wallpapers.values {
//
//            wallpaper.play()
//        }
//    }
//
//    func pauseAll() {
//
//        for wallpaper in wallpapers.values {
//
//            wallpaper.pause()
//        }
//    }
//}
//
//enum MultiDisplayWallpaperError:
//    LocalizedError {
//
//    case displayNotFound
//
//    var errorDescription: String? {
//
//        switch self {
//
//        case .displayNotFound:
//
//            return
//                "The selected display is no longer available."
//        }
//    }
//}


import AppKit
import Foundation
import Combine
import OSLog

@MainActor
final class MultiDisplayWallpaperManager: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var activeDisplayIDs:
        Set<CGDirectDisplayID> = []

    // MARK: - Private Properties

    private var wallpapers:
        [CGDirectDisplayID: DisplayWallpaper] = [:]

    private var wallpaperIsActive = false

    private let displayManager:
        DisplayManager

    private let logger = Logger(
        subsystem:
            Bundle.main.bundleIdentifier
            ?? "MacLiveWallpaper",
        category: "MultiDisplay"
    )

    // MARK: - Initialization

    init(
        displayManager: DisplayManager
    ) {

        self.displayManager =
            displayManager

        // Create wallpaper objects for
        // displays that are already connected.
        synchronizeDisplays()
    }
    // MARK: - Display Synchronization

    func synchronizeDisplays() {

        let currentDisplays =
            displayManager.displays

        let currentIDs =
            Set(
                currentDisplays.map {
                    $0.id
                }
            )

        let existingIDs =
            Set(
                wallpapers.keys
            )

        // MARK: Remove Disconnected Displays

        let removedIDs =
            existingIDs.subtracting(
                currentIDs
            )

        for displayID in removedIDs {

            logger.info(
                "Removing wallpaper for display \(displayID)."
            )

            wallpapers[
                displayID
            ]?.hide()

            wallpapers[
                displayID
            ] = nil
        }

        // MARK: Add New Displays

        for display in currentDisplays {

            if wallpapers[display.id] == nil {

                logger.info(
                    "Creating wallpaper for display \(display.id)."
                )

                let wallpaper =
                    DisplayWallpaper(
                        display: display
                    )

                wallpapers[
                    display.id
                ] = wallpaper
            }

            if wallpaperIsActive {
                updateWallpaperWindow(for: display)
            }
        }

        // MARK: Update Active Displays

        activeDisplayIDs =
            Set(
                wallpapers.keys
            )
    }

    // MARK: - Window Positioning

    private func updateWallpaperWindow(
        for display: DisplayInfo
    ) {

        guard
            let screen =
                screen(
                    for: display.id
                )
        else {
            return
        }

        wallpapers[
            display.id
        ]?.show(
            on: screen
        )
    }

    // MARK: - Find Screen

    private func screen(
        for displayID: CGDirectDisplayID
    ) -> NSScreen? {

        NSScreen.screens.first {

            guard
                let id =
                    $0.deviceDescription[
                        NSDeviceDescriptionKey(
                            "NSScreenNumber"
                        )
                    ] as? CGDirectDisplayID
            else {
                return false
            }

            return id == displayID
        }
    }

    // MARK: - Wallpaper Loading

    func loadVideo(
        from url: URL,
        on displayID: CGDirectDisplayID
    ) async throws {

        guard
            let wallpaper =
                wallpapers[displayID]
        else {

            throw MultiDisplayWallpaperError
                .displayNotFound
        }

        try await wallpaper.loadVideo(
            from: url
        )
    }

    // MARK: - Load On All Displays

    func loadVideoOnAllDisplays(
        from url: URL
    ) async {

        for wallpaper in wallpapers.values {

            do {

                try await wallpaper.loadVideo(
                    from: url
                )

            } catch {

                logger.error(
                    "Failed loading wallpaper on display: \(error.localizedDescription)"
                )
            }
        }
    }

    // MARK: - Playback

    func playAll() {

        wallpaperIsActive = true

        for wallpaper in wallpapers.values {

            wallpaper.play()
        }
    }

    var isPlaying: Bool {
        wallpapers.values.contains {
            $0.playbackController.isPlaying
        }
    }

    func stopAll() {
        wallpaperIsActive = false
        for wallpaper in wallpapers.values {
            wallpaper.stop()
        }
    }

    func showStaticFallback(
        from url: URL,
        on displayID: CGDirectDisplayID
    ) async {

        guard
            let wallpaper =
                wallpapers[displayID]
        else {

            logger.error(
                "Cannot show fallback. Display \(displayID) not found."
            )

            return
        }

        guard
            let screen = screen(
                for: displayID
            )
        else {

            logger.error(
                "Cannot show fallback. Screen \(displayID) not found."
            )

            return
        }

        await wallpaper.showStaticFallback(
            from: url,
            on: screen
        )
    }
    func showStaticFallbackOnAllDisplays(
        from url: URL
    ) async {

        for display in displayManager.displays {

            guard
                let wallpaper =
                    wallpapers[display.id]
            else {
                continue
            }

            guard
                let screen =
                    screen(for: display.id)
            else {
                continue
            }

            await wallpaper.showStaticFallback(
                from: url,
                on: screen
            )
        }
    }
    // MARK: - Pause

    func pauseAll() {

        for wallpaper in wallpapers.values {

            wallpaper.pause()
        }
    }
    // MARK: - Hide All

    func hideAll() {

        wallpaperIsActive = false

        for wallpaper in wallpapers.values {

            wallpaper.hide()
        }
    }
}

// MARK: - Errors

enum MultiDisplayWallpaperError:
    LocalizedError {

    case displayNotFound

    var errorDescription: String? {

        switch self {

        case .displayNotFound:

            return
                "The selected display is no longer available."
        }
    }
}
