//
//  StaticWallpaperService.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 02/10/26.
//

import AppKit
import AVFoundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import OSLog

@MainActor
struct StaticWallpaperService {

    private let workspace = NSWorkspace.shared

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier
            ?? "MacLiveWallpaper",
        category: "StaticWallpaper"
    )

    // MARK: - Cache Directory

    private var cacheDirectory: URL {

        let fileManager = FileManager.default

        let baseDirectory =
            fileManager.urls(
                for: .cachesDirectory,
                in: .userDomainMask
            )[0]

        let directory =
            baseDirectory
                .appendingPathComponent(
                    "MacLiveWallpaper",
                    isDirectory: true
                )
                .appendingPathComponent(
                    "StaticWallpapers",
                    isDirectory: true
                )

        do {

            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )

        } catch {

            logger.error(
                "Failed to create static wallpaper cache directory: \(error.localizedDescription)"
            )
        }

        return directory
    }

    // MARK: - Generate Fallback

    func createFallbackImage(
        from videoURL: URL
    ) async throws -> URL {

        logger.info(
            "Creating static fallback from \(videoURL.lastPathComponent)"
        )

        
        
        
        
        let asset = AVURLAsset(url: videoURL)

        let duration = try await asset.load(.duration)

        guard duration.isNumeric else {
            throw StaticWallpaperError.invalidVideoDuration
        }

        let requestedTime: CMTime

        if duration.seconds > 1.0 {
            requestedTime = CMTime(
                seconds: 1.0,
                preferredTimescale: 600
            )
        } else {
            requestedTime = .zero
        }

        let imageGenerator = AVAssetImageGenerator(
            asset: asset
        )

        imageGenerator.appliesPreferredTrackTransform = true

        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero

        imageGenerator.appliesPreferredTrackTransform = true

        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero

        let result = try await imageGenerator.image(
            at: requestedTime
        )

        let image = result.image
        let fileName =
            "\(videoURL.deletingPathExtension().lastPathComponent)-fallback-\(UUID().uuidString).jpg"

        let outputURL =
            cacheDirectory
                .appendingPathComponent(
                    fileName
                )

        try writeJPEG(
            image: image,
            to: outputURL
        )

        logger.info(
            "Static fallback created: \(outputURL.path)"
        )

        return outputURL
    }

    // MARK: - Set Desktop Wallpaper

    @MainActor
    func setDesktopWallpaper(
        imageURL: URL,
        on screen: NSScreen
    ) throws {

        logger.info(
            "Setting static wallpaper on \(screen.localizedName)"
        )

        
        let options: [NSWorkspace.DesktopImageOptionKey: Any] = [:]

        try workspace.setDesktopImageURL(
            imageURL,
            for: screen,
            options: options
        )

        logger.info(
            "Static wallpaper successfully applied to \(screen.localizedName)"
        )
    }

    // MARK: - Video → Desktop Wallpaper

    func setFallbackWallpaper(
        from videoURL: URL,
        on screen: NSScreen
    ) async throws {

        let imageURL =
            try await createFallbackImage(
                from: videoURL
            )

        try setDesktopWallpaper(
            imageURL: imageURL,
            on: screen
        )
    }

    // MARK: - Remove Cached Images

    func cleanCache() {

        let fileManager = FileManager.default

        do {

            let files =
                try fileManager.contentsOfDirectory(
                    at: cacheDirectory,
                    includingPropertiesForKeys: nil
                )

            for file in files {

                try fileManager.removeItem(
                    at: file
                )
            }

            logger.info(
                "Static wallpaper cache cleaned."
            )

        } catch {

            logger.error(
                "Failed to clean static wallpaper cache: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - JPEG Writer

    private func writeJPEG(
        image: CGImage,
        to url: URL
    ) throws {

        guard
            let destination =
                CGImageDestinationCreateWithURL(
                    url as CFURL,
                    UTType.jpeg.identifier as CFString,
                    1,
                    nil
                )
        else {

            throw StaticWallpaperError
                .cannotCreateImageDestination
        }

        let properties: [CFString: Any] = [

            kCGImageDestinationLossyCompressionQuality:
                0.95
        ]

        CGImageDestinationAddImage(
            destination,
            image,
            properties as CFDictionary
        )

        guard
            CGImageDestinationFinalize(
                destination
            )
        else {

            throw StaticWallpaperError
                .cannotWriteImage
        }
    }
}

// MARK: - Errors

enum StaticWallpaperError:
    LocalizedError {

    case invalidVideoDuration
    case cannotCreateImageDestination
    case cannotWriteImage

    var errorDescription: String? {

        switch self {

        case .invalidVideoDuration:

            return
                "The video does not contain a valid duration."

        case .cannotCreateImageDestination:

            return
                "The fallback image could not be created."

        case .cannotWriteImage:

            return
                "The fallback image could not be saved."
        }
    }
}
