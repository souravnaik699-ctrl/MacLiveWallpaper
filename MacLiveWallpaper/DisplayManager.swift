//
//  DisplayManager.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//


import AppKit
import Combine
import CoreGraphics
import OSLog

@MainActor
final class DisplayManager: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var displays:
        [DisplayInfo] = []

    // MARK: - Private State

    private var displayChangeTask:
        Task<Void, Never>?

    private var refreshTask: Task<Void, Never>?

    private let logger =
        Logger(
            subsystem:
                Bundle.main.bundleIdentifier
                ?? "MacLiveWallpaper",
            category: "DisplayManager"
        )

    // MARK: - Initialization

    init() {

        refreshDisplays()
        startObservingDisplayChanges()
    }

    // MARK: - Deinitialization

    deinit {

        displayChangeTask?.cancel()
        refreshTask?.cancel()
    }

    // MARK: - Refresh

    func refreshDisplays() {

        let screens =
            NSScreen.screens

        displays =
            screens.map {
                DisplayInfo(
                    screen: $0
                )
            }

        logger.info(
            "Display list refreshed: \(self.displays.count) display(s)"
        )
    }

    // MARK: - Display Change Observation

    private func startObservingDisplayChanges() {

        displayChangeTask =
            Task { @MainActor [weak self] in

                let notifications =
                    NotificationCenter.default.notifications(
                        named:
                            NSApplication
                            .didChangeScreenParametersNotification
                    )

                for await _ in notifications {

                    guard
                        !Task.isCancelled
                    else {
                        break
                    }

                    guard let self else {
                        break
                    }

                    // macOS can emit several screen-parameter notifications
                    // for one configuration change. Coalesce them so the
                    // wallpaper windows are rebuilt once after the change.
                    self.refreshTask?.cancel()
                    self.refreshTask = Task { @MainActor [weak self] in
                        try? await Task.sleep(for: .milliseconds(150))
                        guard !Task.isCancelled else { return }
                        self?.refreshDisplays()
                    }
                }
            }
    }

    // MARK: - Helpers

    func display(
        withID id: CGDirectDisplayID
    ) -> DisplayInfo? {

        displays.first {
            $0.id == id
        }
    }

    func mainDisplay() -> DisplayInfo? {

        displays.first {
            $0.isMain
        }
    }

    var displayCount: Int {

        displays.count
    }
}
