//
//  DisplayInfo.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//

import AppKit
import CoreGraphics

struct DisplayInfo: Identifiable, Hashable {

    let id: CGDirectDisplayID
    let name: String
    let frame: CGRect
    let backingScaleFactor: CGFloat
    let isMain: Bool

    init(screen: NSScreen) {
        self.id =
            screen.deviceDescription[
                NSDeviceDescriptionKey("NSScreenNumber")
            ] as? CGDirectDisplayID
            ?? CGMainDisplayID()

        self.name = screen.localizedName
        self.frame = screen.frame
        self.backingScaleFactor = screen.backingScaleFactor
        self.isMain =
            self.id == CGMainDisplayID()
    }

    static func == (
        lhs: DisplayInfo,
        rhs: DisplayInfo
    ) -> Bool {
        lhs.id == rhs.id
    }

    func hash(
        into hasher: inout Hasher
    ) {
        hasher.combine(id)
    }
}
