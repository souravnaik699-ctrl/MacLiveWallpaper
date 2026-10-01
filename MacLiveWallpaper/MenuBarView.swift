//
//  MenuBarView.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//



//import SwiftUI
//import AppKit
//
//struct MenuBarView: View {
//
//    @Environment(\.openWindow) private var openWindow
//
//
//    let isPlaying: Bool
//    let displayCount: Int
//    let loginItemEnabled: Bool
//
//    let onPlay: () -> Void
//    let onPause: () -> Void
//    let onStop: () -> Void
//    let onToggleLoginItem: () -> Void
//    let onOpenLoginItemsSettings: () -> Void
//    let onOpenApp: () -> Void
//    let onQuit: () -> Void
//
//    var body: some View {
//
//        VStack(alignment: .leading, spacing: 0) {
//
//            // MARK: Header
//
//            VStack(alignment: .leading, spacing: 4) {
//
//                Label(
//                    "MAC LIVE WALLPAPER",
//                    systemImage: "play.rectangle.fill"
//                )
//                .font(.headline)
//
//                Text(
//                    isPlaying
//                    ? "Wallpaper is playing"
//                    : "Wallpaper is paused"
//                )
//                .font(.caption)
//                .foregroundStyle(.secondary)
//            }
//            .padding(.bottom, 8)
//
//            Divider()
//
//            // MARK: Playback
//
//            Button {
//                onPlay()
//            } label: {
//                Label(
//                    "Play",
//                    systemImage: "play.fill"
//                )
//            }
//            .disabled(isPlaying)
//
//            Button {
//                onPause()
//            } label: {
//                Label(
//                    "Pause",
//                    systemImage: "pause.fill"
//                )
//            }
//            .disabled(!isPlaying)
//
//            Button {
//                onStop()
//            } label: {
//                Label(
//                    "Stop",
//                    systemImage: "stop.fill"
//                )
//            }
//
//            Divider()
//                .padding(.vertical, 4)
//
//            // MARK: Displays
//
//            Label(
//                "\(displayCount) Display\(displayCount == 1 ? "" : "s") Active",
//                systemImage: "display"
//            )
//            .foregroundStyle(.secondary)
//
//            Divider()
//                .padding(.vertical, 4)
//
//            // MARK: Open Main Application
//
//            Button {
//                openWindow(id: "main")
//
//                NSApp.activate(
//                    ignoringOtherApps: true
//                )
//
//            } label: {
//                Label(
//                    "Open MAC LIVE WALLPAPER",
//                    systemImage: "macwindow"
//                )
//            }
//
//            Divider()
//                .padding(.vertical, 4)
//
//            // MARK: Quit
//
//            Button {
//                onQuit()
//            } label: {
//                Label(
//                    "Quit MAC LIVE WALLPAPER",
//                    systemImage: "power"
//                )
//            }
//        }
//        .padding(12)
//        .frame(width: 260)
//    }
//}






import SwiftUI
import AppKit

struct MenuBarView: View {

    @Environment(\.openWindow) private var openWindow

    let isPlaying: Bool
    let displayCount: Int
    let loginItemEnabled: Bool

    let onPlay: () -> Void
    let onPause: () -> Void
    let onStop: () -> Void
    let onToggleLoginItem: () -> Void
    let onOpenLoginItemsSettings: () -> Void
    let onOpenApp: () -> Void
    let onQuit: () -> Void

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            // MARK: Header

            VStack(alignment: .leading, spacing: 4) {

                Label(
                    "MAC LIVE WALLPAPER",
                    systemImage: "play.rectangle.fill"
                )
                .font(.headline)

                Text(
                    isPlaying
                    ? "Wallpaper is playing"
                    : "Wallpaper is paused"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)

            Divider()

            // MARK: Playback

            Button {
                onPlay()
            } label: {
                Label(
                    "Play",
                    systemImage: "play.fill"
                )
            }
            .disabled(isPlaying)

            Button {
                onPause()
            } label: {
                Label(
                    "Pause",
                    systemImage: "pause.fill"
                )
            }
            .disabled(!isPlaying)

            Button {
                onStop()
            } label: {
                Label(
                    "Stop",
                    systemImage: "stop.fill"
                )
            }

            Divider()
                .padding(.vertical, 4)

            // MARK: Displays

            Label(
                "\(displayCount) Display\(displayCount == 1 ? "" : "s") Active",
                systemImage: "display"
            )
            .foregroundStyle(.secondary)

            Divider()
                .padding(.vertical, 4)

            // MARK: Login Item

            Button {
                onToggleLoginItem()
            } label: {

                Label(
                    "Start at Login",
                    systemImage:
                        loginItemEnabled
                        ? "checkmark.circle.fill"
                        : "circle"
                )
            }

            Button {
                onOpenLoginItemsSettings()
            } label: {

                Label(
                    "Login Items Settings",
                    systemImage: "gear"
                )
            }

            Divider()
                .padding(.vertical, 4)

            // MARK: Open Main Application


            Button {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("Open MAC LIVE WALLPAPER", systemImage: "macwindow")
            }

            Divider()
                .padding(.vertical, 4)

            // MARK: Quit

            Button {
                onQuit()
            } label: {
                Label(
                    "Quit MAC LIVE WALLPAPER",
                    systemImage: "power"
                )
            }
        }
        .padding(12)
        .frame(width: 260)
    }
}

