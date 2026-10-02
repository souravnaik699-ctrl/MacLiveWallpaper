//
//  SystemEventMonitor.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 02/10/26.
//

import AppKit
import Combine
import OSLog

@MainActor
final class SystemEventMonitor: ObservableObject {

    private var observers: [NSObjectProtocol] = []

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "MacLiveWallpaper",
        category: "SystemEvents"
    )

    init() {
        observeDisplayChanges()
        observeWorkspaceEvents()

        logger.info("System event monitor started.")
    }

    // MARK: - Display Changes

    private func observeDisplayChanges() {
        let observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: NSApp,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }

            self.logger.info(
                "Display configuration changed."
            )
        }

        observers.append(observer)
    }

    // MARK: - Workspace Events

    private func observeWorkspaceEvents() {

        let notificationCenter =
            NSWorkspace.shared.notificationCenter

        let wakeObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: NSWorkspace.shared,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }

            self.logger.info(
                "Mac woke from sleep."
            )
        }

        let screenWakeObserver = notificationCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: NSWorkspace.shared,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }

            self.logger.info(
                "Display screens woke."
            )
        }

        let screenSleepObserver = notificationCenter.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: NSWorkspace.shared,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }

            self.logger.info(
                "Display screens went to sleep."
            )
        }

        let sessionActiveObserver = notificationCenter.addObserver(
            forName: NSWorkspace.sessionDidBecomeActiveNotification,
            object: NSWorkspace.shared,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }

            self.logger.info(
                "User session became active."
            )
        }

        let sessionInactiveObserver = notificationCenter.addObserver(
            forName: NSWorkspace.sessionDidResignActiveNotification,
            object: NSWorkspace.shared,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }

            self.logger.info(
                "User session became inactive."
            )
        }

        observers.append(wakeObserver)
        observers.append(screenWakeObserver)
        observers.append(screenSleepObserver)
        observers.append(sessionActiveObserver)
        observers.append(sessionInactiveObserver)
    }
}
