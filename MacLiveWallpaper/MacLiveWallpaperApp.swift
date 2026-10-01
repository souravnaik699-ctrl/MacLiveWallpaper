//
//  MacLiveWallpaperApp.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 30/09/26.
//

import SwiftUI
import AppKit

@main
struct MacLiveWallpaperApp: App {

    var body: some Scene {

        // Main application window
        WindowGroup(id: "main") {
            ContentView()
        }

        // Menu bar application
        MenuBarExtra(
            "MAC LIVE WALLPAPER",
            systemImage: "play.rectangle.fill"
        ) {

            MenuBarView(
                isPlaying: false,
                displayCount: 1,

                onPlay: {
                    // TODO:
                    // Connect to wallpaper engine.
                },

                onPause: {
                    // TODO:
                    // Connect to wallpaper engine.
                },

                onStop: {
                    // TODO:
                    // Connect to wallpaper engine.
                },

                onQuit: {
                    NSApp.terminate(nil)
                }
            )
        }
        .menuBarExtraStyle(.menu)
    }
}
