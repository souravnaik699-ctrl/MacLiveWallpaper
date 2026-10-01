//
//  DisplayWallpaperAssignment.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//

import Foundation
import CoreGraphics

struct DisplayWallpaperAssignment:
    Codable,
    Identifiable {

    let displayID: UInt32

    var wallpaperID: UUID?

    var id: UInt32 {
        displayID
    }
}
