//
//  ContentView.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 30/09/26.
//


import SwiftUI

struct ContentView: View {

@State private var statusMessage = "Ready"
@State private var hasWallpaper = false
@State private var showingSettings = false
@State private var isImporting = false
@State private var metadata: VideoMetadata?
@State private var bookmarkData: Data?

var body: some View {
    VStack(spacing: 0) {

        // MARK: - Header

        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("MAC LIVE WALLPAPER")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Your animated desktop, made simple.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .help("Settings")
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)

        Divider()

        // MARK: - Preview

        VStack(alignment: .leading, spacing: 12) {

            Text("Current Wallpaper")
                .font(.headline)

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.quaternary)

                VStack(spacing: 12) {

                    Image(
                        systemName: metadata == nil
                            ? "rectangle.on.rectangle.slash"
                            : "video.fill"
                    )
                    .font(.system(size: 42))
                    .foregroundStyle(.secondary)

                    if let metadata {
                        Text(metadata.fileName)
                            .font(.headline)
                            .lineLimit(1)

                        Text(
                            "\(metadata.width) × \(metadata.height)"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        Text(
                            "\(metadata.codec) • \(formattedDuration(metadata.duration))"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    } else {
                        Text("No Wallpaper Selected")
                            .font(.headline)

                        Text("Add an MP4 or MOV video to begin.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .multilineTextAlignment(.center)
                .padding()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 250)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)

        // MARK: - Add Button

        Button {
            importWallpaper()
        } label: {
            if isImporting {
                ProgressView()
                    .controlSize(.small)
            } else {
                Label(
                    "Add Wallpaper",
                    systemImage: "plus"
                )
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isImporting)
        .padding(.horizontal, 24)
        .padding(.top, 20)

        // MARK: - Controls

        HStack(spacing: 10) {

            Button {
                setWallpaper()
            } label: {
                Label(
                    "Set Wallpaper",
                    systemImage: "desktopcomputer"
                )
            }
            .disabled(!hasWallpaper)

            Button {
                playWallpaper()
            } label: {
                Label(
                    "Play",
                    systemImage: "play.fill"
                )
            }
            .disabled(!hasWallpaper)

            Button {
                pauseWallpaper()
            } label: {
                Label(
                    "Pause",
                    systemImage: "pause.fill"
                )
            }
            .disabled(!hasWallpaper)

            Button(role: .destructive) {
                removeWallpaper()
            } label: {
                Label(
                    "Remove",
                    systemImage: "trash"
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
                .frame(width: 8, height: 8)

            Text("Status:")
                .fontWeight(.medium)

            Text(statusMessage)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .font(.caption)
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
    .frame(minWidth: 700, minHeight: 600)
    .sheet(isPresented: $showingSettings) {
        SettingsView()
    }
}

// MARK: - Import

private func importWallpaper() {

    isImporting = true
    statusMessage = "Choose an MP4 or MOV video..."

    Task {
        do {
            let result =
                try await VideoImportService.selectAndImportVideo()

            metadata = result.metadata
            bookmarkData = result.bookmarkData
            hasWallpaper = true

            statusMessage =
                "Video imported successfully."

        } catch let error as VideoImportError {

            statusMessage =
                error.localizedDescription

        } catch {

            statusMessage =
                "Could not import the video: \(error.localizedDescription)"
        }

        isImporting = false
    }
}

// MARK: - Placeholder Controls

private func setWallpaper() {
    statusMessage =
        "Wallpaper engine will be connected in Stage 5."
}

private func playWallpaper() {
    statusMessage =
        "Video playback will be connected in Stage 4."
}

private func pauseWallpaper() {
    statusMessage =
        "Video playback will be connected in Stage 4."
}

private func removeWallpaper() {
    metadata = nil
    bookmarkData = nil
    hasWallpaper = false

    statusMessage = "Wallpaper removed."
}

// MARK: - Formatting

private func formattedDuration(
    _ seconds: Double
) -> String {

    guard seconds.isFinite, seconds >= 0 else {
        return "Unknown duration"
    }

    let totalSeconds = Int(seconds.rounded())
    let minutes = totalSeconds / 60
    let remainingSeconds = totalSeconds % 60

    return String(
        format: "%d:%02d",
        minutes,
        remainingSeconds
    )
}

private var statusColor: Color {
    if isImporting {
        return .orange
    }

    if metadata != nil {
        return .green
    }

    return .secondary
}

}

// MARK: - Settings

struct SettingsView: View {

@Environment(\.dismiss) private var dismiss

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
                systemImage: "gearshape"
            )

            Text(
                "General settings will be implemented in Stage 13."
            )
            .foregroundStyle(.secondary)

            Label(
                "Display",
                systemImage: "display"
            )

            Text(
                "Display settings will be implemented in Stage 13."
            )
            .foregroundStyle(.secondary)

            Label(
                "Performance",
                systemImage: "speedometer"
            )

            Text(
                "Performance settings will be implemented in Stage 9."
            )
            .foregroundStyle(.secondary)
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

#Preview {
ContentView()
}
