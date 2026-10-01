//
//  DisplayWallpaperStore.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//

import Foundation
import CoreGraphics
import Combine

@MainActor
final class DisplayWallpaperStore:
    ObservableObject {

    @Published private(set) var assignments:
        [UInt32: UUID] = [:]

    private let key =
        "DisplayWallpaperAssignments"

    init() {

        load()
    }

    func wallpaperID(
        for displayID: CGDirectDisplayID
    ) -> UUID? {

        assignments[
            UInt32(displayID)
        ]
    }

    func setWallpaper(
        _ wallpaperID: UUID?,
        for displayID: CGDirectDisplayID
    ) {

        let key =
            UInt32(displayID)

        assignments[key] =
            wallpaperID

        save()
    }

    func removeDisplay(
        _ displayID: CGDirectDisplayID
    ) {

        assignments[
            UInt32(displayID)
        ] = nil

        save()
    }

    private func load() {

        guard
            let data =
                UserDefaults.standard.data(
                    forKey: key
                )
        else {
            return
        }

        do {

            assignments =
                try JSONDecoder().decode(
                    [UInt32: UUID].self,
                    from: data
                )

        } catch {

            assignments = [:]
        }
    }

    private func save() {

        do {

            let data =
                try JSONEncoder().encode(
                    assignments
                )

            UserDefaults.standard.set(
                data,
                forKey: key
            )

        } catch {

            // Persistence failure is non-fatal.
        }
    }
}
