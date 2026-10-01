//
//  WallpaperPerformanceMode.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//

import Foundation

enum WallpaperPerformanceMode: String, Codable, CaseIterable, Identifiable {
    case quality
    case balanced
    case batterySaver

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .quality:
            return "Quality"

        case .balanced:
            return "Balanced"

        case .batterySaver:
            return "Battery Saver"
        }
    }

    var description: String {
        switch self {
        case .quality:
            return "Prioritizes continuous wallpaper playback."

        case .balanced:
            return "Balances wallpaper playback and battery usage."

        case .batterySaver:
            return "Aggressively reduces wallpaper power usage."
        }
    }
}
