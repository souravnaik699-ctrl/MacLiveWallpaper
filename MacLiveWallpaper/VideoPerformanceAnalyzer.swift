//
//  VideoPerformanceAnalyzer.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//

import Foundation
import AVFoundation
import CoreMedia
import OSLog

struct VideoPerformanceReport {
    let isPlayable: Bool
    let isDecodable: Bool
    let width: Int
    let height: Int
    let frameRate: Double
    let codec: String?
    let warning: String?
}

enum VideoPerformanceAnalyzer {

    static func analyze(
        url: URL
    ) async throws -> VideoPerformanceReport {

        let asset = AVURLAsset(url: url)

        let tracks =
            try await asset.loadTracks(
                withMediaType: .video
            )

        guard let track = tracks.first else {

            return VideoPerformanceReport(
                isPlayable: false,
                isDecodable: false,
                width: 0,
                height: 0,
                frameRate: 0,
                codec: nil,
                warning: "No video track was found."
            )
        }

        let isPlayable =
            try await track.load(.isPlayable)

        let isDecodable =
            try await track.load(.isDecodable)

        let size =
            try await track.load(.naturalSize)

        let frameRate =
            try await track.load(.nominalFrameRate)

        let descriptions =
            try await track.load(
                .formatDescriptions
            )

        let codec =
            descriptions.first.map {
                fourCC(
                    CMFormatDescriptionGetMediaSubType($0)
                )
            }

        let width = Int(abs(size.width))
        let height = Int(abs(size.height))

        var warning: String?

        if !isPlayable || !isDecodable {

            warning =
                "This video may not be playable or decodable on this Mac."

        } else if width >= 3840 || height >= 2160 {

            if frameRate >= 60 {

                warning =
                    "4K high-frame-rate video may use significant GPU and battery resources."

            } else {

                warning =
                    "4K video may use significant GPU and battery resources."
            }
        }

        return VideoPerformanceReport(
            isPlayable: isPlayable,
            isDecodable: isDecodable,
            width: width,
            height: height,
            frameRate: Double(frameRate),
            codec: codec,
            warning: warning
        )
    }

    private static func fourCC(
        _ value: FourCharCode
    ) -> String {

        let bytes: [CChar] = [
            CChar((value >> 24) & 0xff),
            CChar((value >> 16) & 0xff),
            CChar((value >> 8) & 0xff),
            CChar(value & 0xff),
            0
        ]

        return String(
            cString: bytes
        )
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }
}
