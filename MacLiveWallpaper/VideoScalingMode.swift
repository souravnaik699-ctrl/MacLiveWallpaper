//
//  VideoScalingMode.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//

import AVFoundation
import Foundation

enum VideoScalingMode: String, CaseIterable, Identifiable {

    case fill
    case fit
    case center

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .fill:
            return "Fill"

        case .fit:
            return "Fit"

        case .center:
            return "Center"
        }
    }

    init(settingValue: String) {
        self = Self.allCases.first {
            $0.displayName.caseInsensitiveCompare(settingValue) == .orderedSame
        } ?? .fill
    }

    var videoGravity: AVLayerVideoGravity {
        switch self {
        case .fill:
            return .resizeAspectFill

        case .fit:
            return .resizeAspect

        case .center:
            // Center is handled manually by PlayerContainerView.
            return .resizeAspect
        }
    }
}
