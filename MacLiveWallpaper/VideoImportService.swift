//
//  VideoImportService.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//

import Foundation
import AppKit
import AVFoundation
import UniformTypeIdentifiers
import OSLog
import CoreMedia

struct VideoMetadata: Sendable {
let fileName: String
let duration: Double
let width: Int
let height: Int
let codec: String
}

enum VideoImportError: LocalizedError {
case noFileSelected
case unsupportedFileType
case securityAccessDenied
case unableToCreateBookmark
case invalidVideo
case noVideoTrack
case metadataUnavailable

var errorDescription: String? {
    switch self {
    case .noFileSelected:
        return "No video was selected."

    case .unsupportedFileType:
        return "Please select an MP4 or MOV video."

    case .securityAccessDenied:
        return "MAC LIVE WALLPAPER could not access the selected video."

    case .unableToCreateBookmark:
        return "The app could not remember access to this video."

    case .invalidVideo:
        return "The selected file is not a valid playable video."

    case .noVideoTrack:
        return "The selected file does not contain a video track."

    case .metadataUnavailable:
        return "The video's metadata could not be read."
    }
}

}

struct VideoImportResult: Sendable {
let bookmarkData: Data
let metadata: VideoMetadata
}

enum VideoImportService {

private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MacLiveWallpaper",
    category: "VideoImport"
)

@MainActor
static func selectAndImportVideo() async throws -> VideoImportResult {

    logger.info("Opening video selection panel.")

    let panel = NSOpenPanel()

    panel.title = "Choose a Wallpaper Video"
    panel.message = "Select an MP4 or MOV video to use as your wallpaper."
    panel.prompt = "Choose Video"

    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.resolvesAliases = true

    panel.allowedContentTypes = [
        .mpeg4Movie,
        .quickTimeMovie
    ]

    let response = panel.runModal()

    guard response == .OK, let url = panel.url else {
        logger.info("User cancelled video selection.")
        throw VideoImportError.noFileSelected
    }

    logger.info("User selected video: \(url.lastPathComponent, privacy: .public)")

    guard isSupportedVideoFile(url) else {
        logger.error("Unsupported video file: \(url.path, privacy: .public)")
        throw VideoImportError.unsupportedFileType
    }

    let hasAccess = url.startAccessingSecurityScopedResource()

    guard hasAccess else {
        logger.error("Could not obtain security-scoped access.")
        throw VideoImportError.securityAccessDenied
    }

    defer {
        url.stopAccessingSecurityScopedResource()
        logger.debug("Released security-scoped access.")
    }

    let bookmarkData: Data

    do {
        bookmarkData = try url.bookmarkData(
            options: [
                .withSecurityScope,
                .securityScopeAllowOnlyReadAccess
            ],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    } catch {
        logger.error(
            "Failed to create security-scoped bookmark: \(error.localizedDescription, privacy: .public)"
        )

        throw VideoImportError.unableToCreateBookmark
    }

    let metadata = try await readMetadata(from: url)

    logger.info(
        "Video imported successfully: \(metadata.fileName, privacy: .public), \(metadata.width)x\(metadata.height), codec \(metadata.codec, privacy: .public)"
    )

    return VideoImportResult(
        bookmarkData: bookmarkData,
        metadata: metadata
    )
}

private static func isSupportedVideoFile(_ url: URL) -> Bool {
    let supportedExtensions = ["mp4", "mov"]

    return supportedExtensions.contains(
        url.pathExtension.lowercased()
    )
}

private static func readMetadata(
    from url: URL
) async throws -> VideoMetadata {

    logger.info("Reading video metadata.")

    let asset = AVURLAsset(url: url)

    do {
        let duration = try await asset.load(.duration)

        guard duration.isValid, duration.seconds >= 0 else {
            logger.error("Invalid video duration.")
            throw VideoImportError.invalidVideo
        }

        let videoTracks = try await asset.loadTracks(withMediaType: .video)

        guard let videoTrack = videoTracks.first else {
            logger.error("No video track found.")
            throw VideoImportError.noVideoTrack
        }

        let naturalSize = try await videoTrack.load(.naturalSize)

        let width = Int(abs(naturalSize.width.rounded()))
        let height = Int(abs(naturalSize.height.rounded()))

        guard width > 0, height > 0 else {
            logger.error("Invalid video dimensions.")
            throw VideoImportError.metadataUnavailable
        }

        let formatDescriptions = try await videoTrack.load(
            .formatDescriptions
        )

        let codec = codecName(
            from: formatDescriptions.first
        )

        return VideoMetadata(
            fileName: url.lastPathComponent,
            duration: duration.seconds,
            width: width,
            height: height,
            codec: codec
        )

    } catch let error as VideoImportError {
        throw error
    } catch {
        logger.error(
            "Failed to read metadata: \(error.localizedDescription, privacy: .public)"
        )

        throw VideoImportError.metadataUnavailable
    }
}

private static func codecName(
    from formatDescription: CMFormatDescription?
) -> String {

    guard let formatDescription else {
        return "Unknown"
    }

    let codecType = CMFormatDescriptionGetMediaSubType(
        formatDescription
    )

    switch codecType {
    case kCMVideoCodecType_H264:
        return "H.264"

    case kCMVideoCodecType_HEVC:
        return "HEVC"

    case kCMVideoCodecType_AppleProRes422:
        return "Apple ProRes 422"

    case kCMVideoCodecType_AppleProRes4444:
        return "Apple ProRes 4444"

    case kCMVideoCodecType_AppleProRes422HQ:
        return "Apple ProRes 422 HQ"

    case kCMVideoCodecType_AppleProRes422LT:
        return "Apple ProRes 422 LT"

    case kCMVideoCodecType_AppleProRes422Proxy:
        return "Apple ProRes 422 Proxy"

    default:
        return fourCCString(codecType)
    }
}

private static func fourCCString(
    _ code: FourCharCode
) -> String {

    let characters: [Character] = [
        Character(UnicodeScalar((code >> 24) & 0xFF)!),
        Character(UnicodeScalar((code >> 16) & 0xFF)!),
        Character(UnicodeScalar((code >> 8) & 0xFF)!),
        Character(UnicodeScalar(code & 0xFF)!)
    ]

    return String(characters)
}

}

