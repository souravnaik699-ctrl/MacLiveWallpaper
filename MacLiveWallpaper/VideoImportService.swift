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

// MARK: - Video Metadata
struct VideoMetadata: Codable, Equatable {

    let fileName: String
    let duration: Double
    let width: Int
    let height: Int
    let codec: String
}

// MARK: - Import Errors

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
            return "No video file was selected."

        case .unsupportedFileType:
            return "Only MP4 and MOV video files are supported."

        case .securityAccessDenied:
            return "macOS denied access to the selected video."

        case .unableToCreateBookmark:
            return "Unable to create a security-scoped bookmark."

        case .invalidVideo:
            return "The selected file is not a valid video."

        case .noVideoTrack:
            return "The selected file does not contain a video track."

        case .metadataUnavailable:
            return "Unable to read video metadata."
        }
    }
}

// MARK: - Import Result

struct VideoImportResult {
    let url: URL
    let bookmarkData: Data
    let metadata: VideoMetadata
}

// MARK: - Video Import Service

@MainActor
final class VideoImportService {

    private static let logger = Logger(
        subsystem: "com.souravnaik.MacLiveWallpaper",
        category: "VideoImport"
    )

    // MARK: Select and Import Video

    static func selectAndImportVideo() async throws -> VideoImportResult {

        logger.info("Opening video file picker.")

        let panel = NSOpenPanel()

        panel.title = "Select a Video Wallpaper"
        panel.message = "Choose an MP4 or MOV video."
        panel.prompt = "Choose Video"

        // Allow only files
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        // MP4 + MOV
        panel.allowedContentTypes = [
            UTType.mpeg4Movie,
            UTType.quickTimeMovie
        ]

        let response = panel.runModal()

        guard response == .OK,
              let selectedURL = panel.url else {

            logger.info("User cancelled video selection.")

            throw VideoImportError.noFileSelected
        }

        logger.info("Selected video: \(selectedURL.path)")

        // MARK: File Type Validation

        guard isSupportedVideoFile(selectedURL) else {

            logger.error(
                "Unsupported video file: \(selectedURL.path)"
            )

            throw VideoImportError.unsupportedFileType
        }

        // MARK: Security Scoped Access

        let accessGranted = selectedURL.startAccessingSecurityScopedResource()

        guard accessGranted else {

            logger.error(
                "Security scoped access denied."
            )

            throw VideoImportError.securityAccessDenied
        }

        // Keep access active while the video is being used.
        // The caller will eventually release it.

        do {

            // MARK: Create Bookmark

            let bookmarkData: Data

            do {

                bookmarkData = try selectedURL.bookmarkData(
                    options: [
                        .withSecurityScope,
                        .securityScopeAllowOnlyReadAccess
                    ],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )

            } catch {

                logger.error(
                    "Failed to create security scoped bookmark: \(error.localizedDescription)"
                )

                selectedURL.stopAccessingSecurityScopedResource()

                throw VideoImportError.unableToCreateBookmark
            }

            // MARK: Read Metadata

            let metadata = try await readVideoMetadata(
                from: selectedURL
            )

            logger.info(
                """
                Video imported successfully.
                File: \(metadata.fileName)
                Resolution: \(metadata.width)x\(metadata.height)
                Duration: \(metadata.duration)
                Codec: \(metadata.codec)
                """
            )

            return VideoImportResult(
                url: selectedURL,
                bookmarkData: bookmarkData,
                metadata: metadata
            )

        } catch let error as VideoImportError {

            selectedURL.stopAccessingSecurityScopedResource()

            throw error

        } catch {

            selectedURL.stopAccessingSecurityScopedResource()

            logger.error(
                "Video import failed: \(error.localizedDescription)"
            )

            throw error
        }
    }

    // MARK: - Supported File Check

    private static func isSupportedVideoFile(
        _ url: URL
    ) -> Bool {

        let fileExtension = url.pathExtension.lowercased()

        return fileExtension == "mp4" ||
               fileExtension == "mov"
    }

    // MARK: - Read Video Metadata

    private static func readVideoMetadata(
        from url: URL
    ) async throws -> VideoMetadata {

        logger.info(
            "Reading video metadata."
        )

        let asset = AVAsset(url: url)

        // MARK: Duration

        let durationTime: CMTime

        do {
            durationTime = try await asset.load(.duration)
        } catch {

            logger.error(
                "Unable to load video duration."
            )

            throw VideoImportError.metadataUnavailable
        }

        let duration = CMTimeGetSeconds(durationTime)

        guard duration.isFinite,
              duration > 0 else {

            logger.error(
                "Invalid video duration."
            )

            throw VideoImportError.invalidVideo
        }

        // MARK: Video Tracks

        let videoTracks: [AVAssetTrack]

        do {
            videoTracks = try await asset.loadTracks(
                withMediaType: .video
            )
        } catch {

            logger.error(
                "Unable to load video tracks."
            )

            throw VideoImportError.metadataUnavailable
        }

        guard let videoTrack = videoTracks.first else {

            logger.error(
                "No video track found."
            )

            throw VideoImportError.noVideoTrack
        }

        // MARK: Natural Size

        let naturalSize: CGSize

        do {
            naturalSize = try await videoTrack.load(
                .naturalSize
            )
        } catch {

            logger.error(
                "Unable to read video dimensions."
            )

            throw VideoImportError.metadataUnavailable
        }

        let width = Int(abs(naturalSize.width))
        let height = Int(abs(naturalSize.height))

        guard width > 0,
              height > 0 else {

            logger.error(
                "Invalid video dimensions."
            )

            throw VideoImportError.invalidVideo
        }

        // MARK: Codec

        let codec = await readCodec(
            from: videoTrack
        )

        // MARK: File Name

        let fileName = url.lastPathComponent

        return VideoMetadata(
            fileName: fileName,
            duration: duration,
            width: width,
            height: height,
            codec: codec
        )
    }

    // MARK: - Read Codec

    private static func readCodec(
        from track: AVAssetTrack
    ) async -> String {

        do {

            let formatDescriptions = try await track.load(
                .formatDescriptions
            )

            guard let formatDescription = formatDescriptions.first else {
                return "Unknown"
            }

            let mediaSubType =
                CMFormatDescriptionGetMediaSubType(
                    formatDescription
                )

            let codec = fourCharacterCode(
                mediaSubType
            )

            switch codec {

            case "avc1":
                return "H.264"

            case "avc3":
                return "H.264"

            case "hvc1":
                return "HEVC / H.265"

            case "hev1":
                return "HEVC / H.265"

            case "apcn":
                return "Apple ProRes 422"

            case "apcs":
                return "Apple ProRes 422 LT"

            case "apch":
                return "Apple ProRes 422 HQ"

            case "apco":
                return "Apple ProRes 422 Proxy"

            case "ap4h":
                return "Apple ProRes 4444"

            case "ap4x":
                return "Apple ProRes 4444 XQ"

            default:
                return codec
            }

        } catch {

            logger.warning(
                "Unable to determine codec."
            )

            return "Unknown"
        }
    }

    // MARK: - Four Character Code

    private static func fourCharacterCode(
        _ code: FourCharCode
    ) -> String {

        let bytes: [UInt8] = [
            UInt8((code >> 24) & 0xFF),
            UInt8((code >> 16) & 0xFF),
            UInt8((code >> 8) & 0xFF),
            UInt8(code & 0xFF)
        ]

        return String(
            bytes: bytes,
            encoding: .ascii
        ) ?? "Unknown"
    }
}
