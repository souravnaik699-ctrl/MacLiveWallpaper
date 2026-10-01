//
//  AppearanceSettingsView.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 02/10/26.
//

import SwiftUI

struct AppearanceSettingsView: View {

    private let scalingModes = [
        "Fill",
        "Fit",
        "Center"
    ]

    @AppStorage(
        AppSettings.scalingMode
    )
    private var scalingMode = "Fill"

    var body: some View {

        Form {

            Section {

                Picker(
                    "Scaling Mode",
                    selection: $scalingMode
                ) {

                    ForEach(
                        scalingModes,
                        id: \.self
                    ) { mode in

                        Text(mode)
                            .tag(mode)
                    }
                }

                Text(
                    descriptionForScalingMode
                )
                .foregroundStyle(.secondary)
                .font(.caption)

            } header: {

                Text("Wallpaper")
            }
        }
        .formStyle(.grouped)
    }

    private var descriptionForScalingMode: String {

        switch scalingMode {

        case "Fill":
            return "Fills the display while preserving the video's aspect ratio."

        case "Fit":
            return "Shows the complete video while preserving its aspect ratio."

        case "Center":
            return "Displays the video at its original size in the center."

        default:
            return ""
        }
    }
}
