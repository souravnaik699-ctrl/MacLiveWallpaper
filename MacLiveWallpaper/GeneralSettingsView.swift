//
//  GeneralSettingsView.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 02/10/26.
//

import SwiftUI

struct GeneralSettingsView: View {

    @AppStorage(
        AppSettings.startAtLogin
    )
    private var startAtLogin = false

    @AppStorage(
        AppSettings.launchWallpaperAutomatically
    )
    private var launchWallpaperAutomatically = true

    var body: some View {

        Form {

            Section {

                Toggle(
                    "Start at Login",
                    isOn: $startAtLogin
                )

                Toggle(
                    "Launch Wallpaper Automatically",
                    isOn: $launchWallpaperAutomatically
                )

            } header: {

                Text("Startup")
            }

            Section {

                Text(
                    "MAC LIVE WALLPAPER starts automatically when you sign in to macOS."
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
