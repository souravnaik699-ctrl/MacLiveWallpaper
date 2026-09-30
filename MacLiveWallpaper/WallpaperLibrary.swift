//
//  WallpaperLibrary.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//

import Foundation
import Combine
import OSLog

// MARK: - Wallpaper Library Item

struct WallpaperLibraryItem: Codable, Identifiable, Equatable {

    let id: UUID

    var bookmarkData: Data

    var metadata: VideoMetadata

    let dateAdded: Date
}


// MARK: - Wallpaper Library

@MainActor
final class WallpaperLibrary: ObservableObject {

    @Published private(set) var items: [WallpaperLibraryItem] = []

    @Published private(set) var selectedItemID: UUID?

    private let userDefaults = UserDefaults.standard

    private let itemsKey = "wallpaperLibrary.items"

    private let selectedItemKey = "wallpaperLibrary.selectedItemID"

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "MacLiveWallpaper",
        category: "WallpaperLibrary"
    )


    // MARK: - Initialization

    init() {

        loadLibrary()

        logger.info(
            "Wallpaper library loaded with \(self.items.count) item(s)."
        )
    }


    // MARK: - Add

    @discardableResult
    func addWallpaper(
        bookmarkData: Data,
        metadata: VideoMetadata
    ) -> WallpaperLibraryItem {

        let item = WallpaperLibraryItem(
            id: UUID(),
            bookmarkData: bookmarkData,
            metadata: metadata,
            dateAdded: Date()
        )

        items.append(item)

        selectedItemID = item.id

        saveLibrary()

        logger.info(
            "Added wallpaper: \(metadata.fileName)"
        )

        return item
    }


    // MARK: - Remove

    func removeWallpaper(
        id: UUID
    ) {

        guard let index = items.firstIndex(where: {
            $0.id == id
        }) else {
            return
        }

        let removedItem = items.remove(at: index)

        if selectedItemID == id {

            selectedItemID = items.last?.id
        }

        saveLibrary()

        logger.info(
            "Removed wallpaper: \(removedItem.metadata.fileName)"
        )
    }


    // MARK: - Selection

    func selectWallpaper(
        id: UUID
    ) {

        guard items.contains(where: {
            $0.id == id
        }) else {
            return
        }

        selectedItemID = id

        saveLibrary()
    }


    // MARK: - Find

    func item(
        withID id: UUID
    ) -> WallpaperLibraryItem? {

        items.first {
            $0.id == id
        }
    }


    // MARK: - Resolve Bookmark

    func resolveURL(
        for itemID: UUID
    ) throws -> URL {

        guard let index = items.firstIndex(where: {
            $0.id == itemID
        }) else {

            throw WallpaperLibraryError.itemNotFound
        }

        var item = items[index]

        var isStale = false

        let resolvedURL = try URL(
            resolvingBookmarkData: item.bookmarkData,
            options: [
                .withSecurityScope
            ],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        // ---------------------------------------------------------
        // Bookmark is stale.
        //
        // The resolved URL is still valid, but Apple recommends
        // creating a fresh bookmark and replacing the old one.
        // ---------------------------------------------------------

        if isStale {

            logger.warning(
                "Bookmark is stale: \(item.metadata.fileName)"
            )

            let refreshedBookmark = try resolvedURL.bookmarkData(
                options: [
                    .withSecurityScope,
                    .securityScopeAllowOnlyReadAccess
                ],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            item.bookmarkData = refreshedBookmark

            items[index] = item

            saveLibrary()

            logger.info(
                "Refreshed stale bookmark: \(item.metadata.fileName)"
            )
        }

        guard FileManager.default.fileExists(
            atPath: resolvedURL.path
        ) else {

            throw WallpaperLibraryError.fileNotFound(
                item.metadata.fileName
            )
        }

        return resolvedURL
    }


    // MARK: - Persistence

    private func saveLibrary() {

        do {

            let encoder = JSONEncoder()

            encoder.dateEncodingStrategy = .iso8601

            let data = try encoder.encode(items)

            userDefaults.set(
                data,
                forKey: itemsKey
            )

            if let selectedItemID {

                userDefaults.set(
                    selectedItemID.uuidString,
                    forKey: selectedItemKey
                )

            } else {

                userDefaults.removeObject(
                    forKey: selectedItemKey
                )
            }

        } catch {

            logger.error(
                "Failed to save wallpaper library: \(error.localizedDescription)"
            )
        }
    }


    // MARK: - Load

    private func loadLibrary() {

        guard let data = userDefaults.data(
            forKey: itemsKey
        ) else {

            items = []
            selectedItemID = nil

            return
        }

        do {

            let decoder = JSONDecoder()

            decoder.dateDecodingStrategy = .iso8601

            items = try decoder.decode(
                [WallpaperLibraryItem].self,
                from: data
            )

        } catch {

            logger.error(
                "Failed to decode wallpaper library: \(error.localizedDescription)"
            )

            items = []
        }

        if let selectedString = userDefaults.string(
            forKey: selectedItemKey
        ) {

            selectedItemID = UUID(
                uuidString: selectedString
            )

        } else {

            selectedItemID = items.first?.id
        }

        // Prevent a selected ID from pointing to an item that no longer exists.

        if let selectedItemID,
           !items.contains(where: {
               $0.id == selectedItemID
           }) {

            self.selectedItemID = items.first?.id
        }
    }
}


// MARK: - Errors

enum WallpaperLibraryError: LocalizedError {

    case itemNotFound

    case fileNotFound(String)

    var errorDescription: String? {

        switch self {

        case .itemNotFound:

            return "The selected wallpaper could not be found in the library."

        case .fileNotFound(let fileName):

            return "The video file could not be found: \(fileName)"
        }
    }
}
