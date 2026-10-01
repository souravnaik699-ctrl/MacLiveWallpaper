//
//  LoginItemManager.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//

import Foundation
import ServiceManagement
import OSLog
import Combine

@MainActor
final class LoginItemManager: ObservableObject {

    @Published private(set) var isEnabled = false

    private let service = SMAppService.mainApp

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier
            ?? "MacLiveWallpaper",
        category: "LoginItem"
    )

    init() {
        refreshStatus()
    }

    // MARK: - Status

    func refreshStatus() {

        switch service.status {

        case .enabled:
            isEnabled = true

        case .notRegistered,
             .requiresApproval,
             .notFound:
            isEnabled = false

        @unknown default:
            isEnabled = false
        }

        logger.info(
            "Login item status: \(String(describing: self.service.status))"
        )
    }

    // MARK: - Enable

    func enable() {

        do {

            try service.register()

            refreshStatus()

            logger.info(
                "MAC LIVE WALLPAPER registered to launch at login."
            )

        } catch {

            logger.error(
                "Failed to register login item: \(error.localizedDescription)"
            )

            refreshStatus()
        }
    }

    // MARK: - Disable

    func disable() {

        do {

            try service.unregister()

            refreshStatus()

            logger.info(
                "MAC LIVE WALLPAPER removed from launch at login."
            )

        } catch {

            logger.error(
                "Failed to unregister login item: \(error.localizedDescription)"
            )

            refreshStatus()
        }
    }

    // MARK: - Toggle

    func toggle() {

        if isEnabled {
            disable()
        } else {
            enable()
        }
    }

    // MARK: - Open System Settings

    func openLoginItemsSettings() {

        SMAppService.openSystemSettingsLoginItems()

        logger.info(
            "Opened macOS Login Items settings."
        )
    }
}
