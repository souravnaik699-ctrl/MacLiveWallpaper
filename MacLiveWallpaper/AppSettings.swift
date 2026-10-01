//
//  AppSettings.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 02/10/26.
//

import Foundation

enum AppSettings {

    // MARK: - General

    static let startAtLogin =
        "settings.startAtLogin"

    static let launchWallpaperAutomatically =
        "settings.launchWallpaperAutomatically"

    // MARK: - Playback

    static let loopWallpaper =
        "settings.loopWallpaper"

    static let startPlaybackAutomatically =
        "settings.startPlaybackAutomatically"

    // MARK: - Appearance

    static let scalingMode =
        "settings.scalingMode"

    // MARK: - Performance

    static let performanceMode =
        "settings.performanceMode"

    static let pauseOnBattery =
        "settings.pauseOnBattery"

    static let pauseOnLowPowerMode =
        "settings.pauseOnLowPowerMode"

    static let batteryThreshold =
        "settings.batteryThreshold"
}
