//
//  WallpaperRecoveryManager.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 02/10/26.
//

import Foundation
import AppKit
import OSLog

@MainActor
final class WallpaperRecoveryManager {

    private let logger = Logger(
        subsystem:
            Bundle.main.bundleIdentifier
            ?? "MacLiveWallpaper",
        category: "WallpaperRecovery"
    )

    private let staticWallpaperService =
        StaticWallpaperService()

    func recover(
        videoURL: URL,
        screen: NSScreen
    ) async {

        logger.warning(
            "Attempting static wallpaper recovery for \(videoURL.lastPathComponent)."
        )

        do {

            try await
                staticWallpaperService
                .setFallbackWallpaper(
                    from: videoURL,
                    on: screen
                )

            logger.info(
                "Static wallpaper recovery succeeded."
            )

        } catch {

            logger.error(
                "Static wallpaper recovery failed: \(error.localizedDescription)"
            )
        }
    }
}
