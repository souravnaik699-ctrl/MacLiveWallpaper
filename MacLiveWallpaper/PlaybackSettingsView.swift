//
//  PlaybackSettingsView.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 02/10/26.
//

import SwiftUI

struct PlaybackSettingsView: View {

    @AppStorage(
        AppSettings.loopWallpaper
    )
    private var loopWallpaper = true

    @AppStorage(
        AppSettings.startPlaybackAutomatically
    )
    private var startPlaybackAutomatically = true

    var body: some View {

        Form {

            Section {

                Toggle(
                    "Loop Wallpaper",
                    isOn: $loopWallpaper
                )

                Toggle(
                    "Start Playback Automatically",
                    isOn: $startPlaybackAutomatically
                )

            } header: {

                Text("Playback")
            }

            Section {

                Text(
                    "Looping uses AVFoundation's playback system."
                )
                .foregroundStyle(.secondary)
                .font(.caption)

            } header: {

                Text("Information")
            }
        }
        .formStyle(.grouped)
    }
}
