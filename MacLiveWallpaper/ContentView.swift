//
//  ContentView.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 30/09/26.
//


import SwiftUI

struct ContentView: View {

    @State private var statusMessage = "Ready"
    @State private var isPlaying = false
    @State private var hasWallpaper = false
    @State private var showingSettings = false

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

                        Image(systemName: hasWallpaper
                              ? "play.rectangle.fill"
                              : "rectangle.on.rectangle.slash")
                            .font(.system(size: 42))
                            .foregroundStyle(.secondary)

                        if hasWallpaper {
                            Text("Wallpaper Preview")
                                .font(.headline)

                            Text("Video preview will be connected in Stage 4.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("No Wallpaper Selected")
                                .font(.headline)

                            Text("Add a video to begin.")
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
                addWallpaper()
            } label: {
                Label("Add Wallpaper", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // MARK: - Playback Controls

            HStack(spacing: 10) {

                Button {
                    setWallpaper()
                } label: {
                    Label("Set Wallpaper", systemImage: "desktopcomputer")
                }
                .disabled(!hasWallpaper)

                Button {
                    playWallpaper()
                } label: {
                    Label("Play", systemImage: "play.fill")
                }
                .disabled(!hasWallpaper)

                Button {
                    pauseWallpaper()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .disabled(!hasWallpaper)

                Button(role: .destructive) {
                    removeWallpaper()
                } label: {
                    Label("Remove", systemImage: "trash")
                }
                .disabled(!hasWallpaper)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Spacer(minLength: 20)

            // MARK: - Status

            HStack(spacing: 8) {
                Circle()
                    .fill(.green)
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

    // MARK: - Actions

    private func addWallpaper() {
        hasWallpaper = true
        statusMessage = "Wallpaper selected — video importing starts in Stage 3."
    }

    private func setWallpaper() {
        statusMessage = "Wallpaper engine will be connected in Stage 5."
    }

    private func playWallpaper() {
        isPlaying = true
        statusMessage = "Playback control is ready — AVPlayer comes in Stage 4."
    }

    private func pauseWallpaper() {
        isPlaying = false
        statusMessage = "Playback paused — AVPlayer comes in Stage 4."
    }

    private func removeWallpaper() {
        hasWallpaper = false
        isPlaying = false
        statusMessage = "Wallpaper removed."
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

            VStack(alignment: .leading, spacing: 14) {

                Label("General", systemImage: "gearshape")

                Text("General settings will be implemented in Stage 13.")
                    .foregroundStyle(.secondary)

                Label("Display", systemImage: "display")

                Text("Display settings will be implemented in Stage 13.")
                    .foregroundStyle(.secondary)

                Label("Performance", systemImage: "speedometer")

                Text("Performance settings will be implemented in Stage 9.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding(24)
        .frame(width: 500, height: 400)
    }
}

#Preview {
    ContentView()
}
