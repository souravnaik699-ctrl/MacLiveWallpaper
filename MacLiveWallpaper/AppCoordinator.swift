//
//  AppCoordinator.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 02/10/26.
//

import AppKit
import Combine
import OSLog


@MainActor
final class AppCoordinator: ObservableObject {

    let displayManager: DisplayManager
    let multiDisplayWallpaperManager:
        MultiDisplayWallpaperManager

    let wallpaperLibrary: WallpaperLibrary

    let performanceController:
        WallpaperPerformanceController

    let loginItemManager:
        LoginItemManager

    private let logger = Logger(
        subsystem:
            Bundle.main.bundleIdentifier
            ?? "MacLiveWallpaper",
        category: "AppCoordinator"
    )

    private var cancellables = Set<AnyCancellable>()

    init() {

        logger.info("Initializing application coordinator.")

        self.displayManager =
            DisplayManager()

        self.wallpaperLibrary =
            WallpaperLibrary()

        self.multiDisplayWallpaperManager =
            MultiDisplayWallpaperManager(
                displayManager:
                    self.displayManager
            )

        let playbackController = VideoPlayerController()
        let powerMonitor = SystemPowerMonitor()

        self.performanceController =
            WallpaperPerformanceController(
                playbackController: playbackController,
                powerMonitor: powerMonitor
            )
        self.loginItemManager =
            LoginItemManager()

        observeDisplayChanges()

        logger.info(
            "Application coordinator initialized."
        )
    }

    // MARK: - Display Changes

    private func observeDisplayChanges() {

        displayManager.$displays
            .dropFirst()
            .sink { [weak self] _ in

                guard let self else {
                    return
                }

                self.logger.info(
                    "Display list changed. Synchronizing wallpaper system."
                )

                self.multiDisplayWallpaperManager
                    .synchronizeDisplays()
            }
            .store(
                in: &cancellables
            )
    }

    // MARK: - Startup

    @Published private(set) var startupState:
        AppStartupState = .starting

    func start() {

        logger.info(
            "Starting MAC LIVE WALLPAPER."
        )

        startupState = .starting

        displayManager.refreshDisplays()

        multiDisplayWallpaperManager
            .synchronizeDisplays()

        startupState = .restoring

        restoreSavedWallpapers()

        startupState = .ready

        logger.info(
            "MAC LIVE WALLPAPER startup completed."
        )
    }
    // MARK: - Restore

    private func restoreSavedWallpapers() {

        logger.info(
            "Restoring saved wallpapers."
        )

        for display in displayManager.displays {

            guard
                let wallpaperID =
                    displayWallpaperID(
                        for: display.id
                    )
            else {
                continue
            }

            guard
                wallpaperLibrary.item(
                    withID: wallpaperID
                ) != nil
            else {

                logger.warning(
                    "Saved wallpaper \(wallpaperID.uuidString) no longer exists."
                )

                continue
            }

            Task { @MainActor in

                do {

                    let url =
                        try wallpaperLibrary
                            .resolveURL(
                                for: wallpaperID
                            )

                    try await
                        multiDisplayWallpaperManager
                        .loadVideo(
                            from: url,
                            on: display.id
                        )

                    logger.info(
                        "Restored wallpaper on display \(display.id)."
                    )

                } catch {

                    logger.error(
                        "Failed to restore wallpaper on display \(display.id): \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    // MARK: - Saved Assignment

    private func displayWallpaperID(
        for displayID: CGDirectDisplayID
    ) -> UUID? {

        // This will use DisplayWallpaperStore
        // once it is exposed through the application's
        // central state.
        //
        // Temporary integration point.

        return nil
    }
}
