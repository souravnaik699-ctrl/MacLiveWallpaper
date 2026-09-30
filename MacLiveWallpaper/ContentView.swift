//
//  ContentView.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 30/09/26.
//



import SwiftUI
import AVFoundation

struct ContentView: View {

    // MARK: - State

    @StateObject private var playbackController =
        VideoPlayerController()

    @State private var wallpaperManager =
        WallpaperWindowManager()

    @State private var scalingMode: VideoScalingMode = .fill

    @State private var statusMessage = "Ready"

    @State private var hasWallpaper = false

    @State private var showingSettings = false

    @State private var isImporting = false

    @State private var metadata: VideoMetadata?

    @State private var bookmarkData: Data?

    // MARK: - Body

    var body: some View {

        VStack(spacing: 0) {

            // MARK: - Header

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("MAC LIVE WALLPAPER")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(
                        "Your animated desktop, made simple."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showingSettings = true
                } label: {

                    Image(
                        systemName: "gearshape"
                    )
                    .font(.title3)
                }
                .buttonStyle(.borderless)
                .help("Settings")
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            Divider()

            // MARK: - Video Preview

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                Text("Current Wallpaper")
                    .font(.headline)

                ZStack {

                    RoundedRectangle(
                        cornerRadius: 14
                    )
                    .fill(.black)

                    if playbackController.hasLoadedVideo {

                        VideoPlayerView(
                            player: playbackController.player,
                            scalingMode: scalingMode
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 14
                            )
                        )

                    } else {

                        VStack(spacing: 12) {

                            Image(
                                systemName:
                                    "rectangle.on.rectangle.slash"
                            )
                            .font(
                                .system(size: 42)
                            )
                            .foregroundStyle(
                                .secondary
                            )

                            Text(
                                "No Video Selected"
                            )
                            .font(.headline)

                            Text(
                                "Add an MP4 or MOV video to preview it."
                            )
                            .font(.subheadline)
                            .foregroundStyle(
                                .secondary
                            )
                        }
                        .multilineTextAlignment(
                            .center
                        )
                        .padding()
                    }
                }
                .frame(
                    maxWidth: .infinity
                )
                .frame(height: 300)
                .overlay {

                    if let error =
                        playbackController.playbackError {

                        VStack(spacing: 8) {

                            Image(
                                systemName:
                                    "exclamationmark.triangle.fill"
                            )

                            Text(error)
                                .font(.caption)
                                .multilineTextAlignment(
                                    .center
                                )
                        }
                        .foregroundStyle(
                            .white
                        )
                        .padding()
                        .background(
                            .black.opacity(0.75),
                            in:
                                RoundedRectangle(
                                    cornerRadius: 10
                                )
                        )
                        .padding()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            // MARK: - Metadata

            if let metadata {

                HStack(spacing: 16) {

                    metadataItem(
                        title: "Resolution",
                        value:
                            "\(metadata.width) × \(metadata.height)"
                    )

                    metadataItem(
                        title: "Codec",
                        value: metadata.codec
                    )

                    metadataItem(
                        title: "Duration",
                        value:
                            formattedDuration(
                                metadata.duration
                            )
                    )

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }

            // MARK: - Scaling Mode

            if playbackController.hasLoadedVideo {

                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {

                    Picker(
                        "Scaling",
                        selection: $scalingMode
                    ) {

                        ForEach(
                            VideoScalingMode.allCases
                        ) { mode in

                            Text(
                                mode.displayName
                            )
                            .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)
            }

            // MARK: - Add Button

            Button {

                importWallpaper()

            } label: {

                if isImporting {

                    ProgressView()
                        .controlSize(
                            .small
                        )

                } else {

                    Label(
                        "Add Wallpaper",
                        systemImage: "plus"
                    )
                }
            }
            .buttonStyle(
                .borderedProminent
            )
            .controlSize(.large)
            .disabled(isImporting)
            .padding(.horizontal, 24)
            .padding(.top, 18)

            // MARK: - Playback Controls
        
            HStack(spacing: 10) {

                Button {

                    playbackController.restart()

                    statusMessage =
                        "Restarted."

                } label: {

                    Label(
                        "Restart",
                        systemImage:
                            "backward.end.fill"
                    )
                }
                .disabled(!hasWallpaper)

                Button {

                    playbackController.play()

                    statusMessage =
                        "Playing."

                } label: {

                    Label(
                        "Play",
                        systemImage:
                            "play.fill"
                    )
                }
                .disabled(!hasWallpaper)

                Button {

                    playbackController.pause()

                    statusMessage =
                        "Paused."

                } label: {

                    Label(
                        "Pause",
                        systemImage:
                            "pause.fill"
                    )
                }
                .disabled(!hasWallpaper)

                Button {

                    playbackController.stop()

                    statusMessage =
                        "Stopped."

                } label: {

                    Label(
                        "Stop",
                        systemImage:
                            "stop.fill"
                    )
                }
                .disabled(!hasWallpaper)

                Button {

                    setWallpaper()

                } label: {

                    Label(
                        "Set Wallpaper",
                        systemImage:
                            "desktopcomputer"
                    )
                }
                .disabled(!hasWallpaper)

                Button(
                    role: .destructive
                ) {

                    removeWallpaper()

                } label: {

                    Label(
                        "Remove",
                        systemImage:
                            "trash"
                    )
                }
                .disabled(!hasWallpaper)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            // MARK: - Status

            HStack(spacing: 8) {

                Circle()
                    .fill(statusColor)
                    .frame(
                        width: 8,
                        height: 8
                    )

                Text("Status:")
                    .fontWeight(.medium)

                Text(statusMessage)
                    .foregroundStyle(
                        .secondary
                    )

                Spacer()
            }
            .font(.caption)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(
            minWidth: 760,
            minHeight: 720
        )
        .sheet(
            isPresented:
                $showingSettings
        ) {
            SettingsView()
        }
    }

    // MARK: - Import

    private func importWallpaper() {

        isImporting = true

        statusMessage =
            "Choose an MP4 or MOV video..."

        Task {

            do {

                let result =
                    try await
                    VideoImportService
                        .selectAndImportVideo()

                bookmarkData =
                    result.bookmarkData

                metadata =
                    result.metadata

                playbackController
                    .loadVideo(
                        from: result.url
                    )

                hasWallpaper =
                    playbackController
                        .hasLoadedVideo

                statusMessage =
                    "Video ready."

            } catch let error
                as VideoImportError {

                statusMessage =
                    error.localizedDescription

            } catch {

                statusMessage =
                    "Could not import the video: \(error.localizedDescription)"
            }

            isImporting = false
        }
    }

    // MARK: - Set Wallpaper
    private func setWallpaper() {

        guard let player = playbackController.player else {
            statusMessage = "No video is loaded."
            return
        }

        wallpaperManager.showWallpaper(
            player: player,
            scalingMode: scalingMode
        )

        playbackController.play()

        hasWallpaper = true

        statusMessage = "Live wallpaper is active — \(scalingMode.displayName)."
    }

    // MARK: - Remove Wallpaper

    private func removeWallpaper() {

        wallpaperManager.hideWallpaper()

        playbackController.pause()

        hasWallpaper = false

        statusMessage =
            "Wallpaper removed."
    }

    // MARK: - Metadata Item

    private func metadataItem(
        title: String,
        value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 3
        ) {

            Text(title)
                .font(.caption2)
                .foregroundStyle(
                    .secondary
                )

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }

    // MARK: - Duration

    private func formattedDuration(
        _ seconds: Double
    ) -> String {

        guard seconds.isFinite,
              seconds >= 0 else {

            return "Unknown"
        }

        let totalSeconds =
            Int(seconds.rounded())

        let hours =
            totalSeconds / 3600

        let minutes =
            (totalSeconds % 3600) / 60

        let remainingSeconds =
            totalSeconds % 60

        if hours > 0 {

            return String(
                format:
                    "%d:%02d:%02d",
                hours,
                minutes,
                remainingSeconds
            )
        }

        return String(
            format:
                "%d:%02d",
            minutes,
            remainingSeconds
        )
    }

    // MARK: - Status Color

    private var statusColor: Color {

        if isImporting {
            return .orange
        }

        if playbackController
            .playbackError != nil {

            return .red
        }

        if playbackController
            .isPlaying {

            return .green
        }

        if metadata != nil {

            return .blue
        }

        return .secondary
    }
}


// MARK: - Settings

struct SettingsView: View {

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {

        VStack(spacing: 20) {

            HStack {

                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("Done") {
                    dismiss()
                }
            }

            Divider()

            VStack(
                alignment: .leading,
                spacing: 14
            ) {

                Label(
                    "General",
                    systemImage:
                        "gearshape"
                )

                Text(
                    "General settings will be implemented in Stage 13."
                )
                .foregroundStyle(
                    .secondary
                )

                Label(
                    "Display",
                    systemImage:
                        "display"
                )

                Text(
                    "Display settings will be implemented in Stage 13."
                )
                .foregroundStyle(
                    .secondary
                )

                Label(
                    "Performance",
                    systemImage:
                        "speedometer"
                )

                Text(
                    "Performance settings will be implemented in Stage 9."
                )
                .foregroundStyle(
                    .secondary
                )
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )

            Spacer()
        }
        .padding(24)
        .frame(
            width: 500,
            height: 400
        )
    }
}


// MARK: - Preview

#Preview {
    ContentView()
}
