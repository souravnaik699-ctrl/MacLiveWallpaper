//
//  AppSettingsDefaults.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 02/10/26.
//

import Foundation

enum AppSettingsDefaults {

    static func register() {

        UserDefaults.standard.register(
            defaults: [

                AppSettings.startAtLogin:
                    false,

                AppSettings.launchWallpaperAutomatically:
                    true,

                AppSettings.loopWallpaper:
                    true,

                AppSettings.startPlaybackAutomatically:
                    true,

                AppSettings.scalingMode:
                    "Fill",

                AppSettings.performanceMode:
                    "Balanced",

                AppSettings.pauseOnBattery:
                    false,

                AppSettings.pauseOnLowPowerMode:
                    true,

                AppSettings.batteryThreshold:
                    20
            ]
        )
    }
}
