//
//  ContentView.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 30/09/26.
//

import SwiftUI
import AVFoundation

struct ContentView: View {

    // MARK: - Controllers

    
    @StateObject private var powerMonitor: SystemPowerMonitor

    @StateObject private var performanceController:
        WallpaperPerformanceController
    @StateObject private var displayManager: DisplayManager

    @StateObject private var playbackController:
        VideoPlayerController

    @StateObject private var wallpaperLibrary =
        WallpaperLibrary()

    // MARK: - Wallpaper Engine

    @State private var wallpaperManager =
        WallpaperWindowManager()

    // MARK: - UI State

    @State private var scalingMode:
        VideoScalingMode = .fill

    @State private var statusMessage =
        "No wallpaper selected."

    @State private var showingSettings =
        false

    @State private var isImporting =
        false

    @State private var metadata:
        VideoMetadata?

    @State private var hasWallpaper =
        false

    @State private var selectedItemID: UUID?

    // MARK: - Initialization

    init() {
        let playbackController =
            VideoPlayerController()

        let powerMonitor =
            SystemPowerMonitor()
        let displayManager =
            DisplayManager()

        _playbackController =
            StateObject(
                wrappedValue: playbackController
            )

        _powerMonitor =
            StateObject(
                wrappedValue: powerMonitor
            )
        _displayManager =
            StateObject(
                wrappedValue: displayManager
            )

        _performanceController =
            StateObject(
                wrappedValue:
                    WallpaperPerformanceController(
                        playbackController:
                            playbackController,
                        powerMonitor:
                            powerMonitor
                    )
            )
    }

    // MARK: - Body

    var body: some View {

        VStack(spacing: 0) {

            header

            Divider()

            HStack(spacing: 0) {

                librarySidebar

                Divider()

                mainContent
            }
        }
        .frame(
            minWidth: 900,
            minHeight: 600
        )
        .sheet(isPresented: $showingSettings) {

            SettingsView()
        }
        .task {

            selectedItemID =
                wallpaperLibrary.selectedItemID

            restoreSelectedWallpaper()
        }
    }

    // MARK: - Header

    private var header: some View {

        HStack {

            Text("MAC LIVE WALLPAPER")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Button("Settings") {

                showingSettings = true
            }
        }
        .padding()
    }

    // MARK: - Library Sidebar

    private var librarySidebar: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                Text("Library")
                    .font(.headline)

                Spacer()

                Button {

                    importWallpaper()

                } label: {

                    Image(systemName: "plus")
                }
                .help("Add Wallpaper")
            }

            if wallpaperLibrary.items.isEmpty {

                VStack(spacing: 10) {

                    Image(
                        systemName:
                            "rectangle.stack.badge.plus"
                    )
                    .font(.largeTitle)

                    Text("No wallpapers")

                    Text(
                        "Add a video to create your library."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )

            } else {

                List(
                    wallpaperLibrary.items,
                    selection: $selectedItemID
                ) { item in

                    wallpaperRow(
                        item: item
                    )
                    .tag(item.id)
                }
                .listStyle(.sidebar)
                .onChange(of: selectedItemID) {
                    _,
                    newValue in

                    guard let newValue,
                          newValue !=
                            wallpaperLibrary.selectedItemID
                    else {
                        return
                    }

                    Task { @MainActor in

                        selectWallpaper(
                            id: newValue
                        )
                    }
                }
            }
        }
        .padding()
        .frame(width: 280)
    }

    // MARK: - Library Row

    private func wallpaperRow(
        item: WallpaperLibraryItem
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text(item.metadata.fileName)
                .lineLimit(1)

            Text(
                "\(item.metadata.width) × \(item.metadata.height)"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(
                item.metadata.codec
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contextMenu {

            Button("Remove") {

                removeLibraryItem(
                    id: item.id
                )
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {

        VStack(spacing: 20) {

            previewArea

            metadataArea

            scalingArea

            // Stage 9
            performanceArea

            controls

            statusArea
        }
        .padding(24)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    // MARK: - Preview

    private var previewArea: some View {

        ZStack {

            RoundedRectangle(
                cornerRadius: 12
            )
            .fill(.black)

            if playbackController.hasLoadedVideo {

                VideoPlayerView(
                    player:
                        playbackController.player,
                    scalingMode:
                        scalingMode
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12
                    )
                )

            } else {

                VStack(spacing: 10) {

                    Image(
                        systemName:
                            "play.rectangle"
                    )
                    .font(.system(size: 50))

                    Text("No Video Loaded")

                    Text(
                        "Select a wallpaper from your library."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .foregroundStyle(.secondary)
            }
        }
        .frame(
            minHeight: 300,
            maxHeight: 420
        )
    }

    // MARK: - Metadata

    @ViewBuilder
    private var metadataArea: some View {

        if let metadata {

            HStack(spacing: 24) {

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
                        formatDuration(
                            metadata.duration
                        )
                )

                Spacer()
            }
        }
    }

    private func metadataItem(
        title: String,
        value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    // MARK: - Scaling

    private var scalingArea: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Scaling")
                .font(.headline)

            Picker(
                "Scaling",
                selection: $scalingMode
            ) {

                ForEach(
                    VideoScalingMode.allCases
                ) { mode in

                    Text(mode.displayName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Performance
    // Stage 9

    private var performanceArea: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text("Performance")
                .font(.headline)

            HStack {

                Text("Performance Mode")

                Spacer()

                Picker(
                    "Performance Mode",
                    selection:
                        $performanceController.mode
                ) {

                    ForEach(
                        WallpaperPerformanceMode.allCases
                    ) { mode in

                        Text(mode.displayName)
                            .tag(mode)
                    }
                }
                .frame(width: 180)
            }

            Text(
                performanceController.mode.description
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack {

                Text(
                    "Battery Threshold: " +
                    "\(performanceController.batteryThreshold)%"
                )

                Spacer()

                Stepper(
                    "",
                    value:
                        $performanceController
                            .batteryThreshold,
                    in: 5...50,
                    step: 5
                )
                .labelsHidden()
            }

            HStack(spacing: 8) {

                Circle()
                    .fill(
                        performanceController
                            .isAutomaticallyPaused
                        ? Color.orange
                        : Color.green
                    )
                    .frame(
                        width: 8,
                        height: 8
                    )

                if performanceController
                    .isAutomaticallyPaused {

                    Text(
                        performanceController
                            .pauseReason
                        ?? "Playback paused automatically."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                } else {

                    Text("Performance protection is inactive.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(
                cornerRadius: 10
            )
            .fill(
                Color.secondary.opacity(0.08)
            )
        )
    }

    // MARK: - Controls

    private var controls: some View {

        HStack(spacing: 10) {

            Button("Restart") {

                playbackController.restart()
            }

            Button("Play") {

                playbackController.play()

                performanceController
                    .handleManualPlay()
            }

            Button("Pause") {

                playbackController.pause()

                performanceController
                    .handleManualPause()
            }

            Button("Stop") {

                playbackController.stop()
            }

            Spacer()

            Button("Set Wallpaper") {

                setWallpaper()
            }
            .buttonStyle(.borderedProminent)

            Button("Remove") {

                removeWallpaper()
            }
        }
    }

    // MARK: - Status

    private var statusArea: some View {

        HStack {

            Circle()
                .fill(
                    hasWallpaper
                    ? Color.green
                    : Color.gray
                )
                .frame(
                    width: 8,
                    height: 8
                )

            Text(statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    // MARK: - Import

    private func importWallpaper() {

        isImporting = true

        Task {

            defer {
                isImporting = false
            }

            do {

                let result =
                    try await VideoImportService
                        .selectAndImportVideo()

                // Add the wallpaper to the persistent library.

                let item =
                    wallpaperLibrary.addWallpaper(
                        bookmarkData:
                            result.bookmarkData,
                        metadata:
                            result.metadata
                    )

                // Load it into the current player.

                try await playbackController.loadVideo(
                    from: result.url
                )

                metadata =
                    result.metadata

                statusMessage =
                    "Added \(result.metadata.fileName) to the library."

                selectedItemID = item.id

            } catch {

                statusMessage =
                    error.localizedDescription
            }
        }
    }

    // MARK: - Select Wallpaper

    private func selectWallpaper(
        id: UUID
    ) {

        wallpaperLibrary.selectWallpaper(
            id: id
        )

        Task {

            guard let item =
                    wallpaperLibrary.item(
                        withID: id
                    )
            else {

                statusMessage =
                    "Wallpaper not found."

                return
            }

            do {

                let url =
                    try wallpaperLibrary.resolveURL(
                        for: id
                    )

                try await playbackController.loadVideo(
                    from: url
                )

                metadata =
                    item.metadata

                statusMessage =
                    "Loaded \(item.metadata.fileName)."

            } catch {

                playbackController.unloadVideo()

                metadata = nil

                statusMessage =
                    error.localizedDescription
            }
        }
    }

    // MARK: - Restore Selected Wallpaper

    private func restoreSelectedWallpaper() {

        guard let selectedID =
                wallpaperLibrary.selectedItemID
        else {
            return
        }
        Task {
            do {
                let url =
                    try wallpaperLibrary.resolveURL(
                        for: selectedID
                    )

                let report =
                    try await VideoPerformanceAnalyzer.analyze(
                        url: url
                    )

                if let warning = report.warning {
                    statusMessage = warning
                }

                try await playbackController.loadVideo(
                    from: url
                )

            } catch {
                playbackController.unloadVideo()
                metadata = nil
                statusMessage =
                    error.localizedDescription
            }
        }
    }

    // MARK: - Set Wallpaper
    
    private func setWallpaper() {

        guard let player = playbackController.player else {
            statusMessage = "No video is loaded."
            return
        }

        wallpaperManager.showWallpaper(
            player: player
        )

        playbackController.play()

        // Let Stage 9 evaluate power/performance
        // conditions immediately.
        performanceController.evaluate(
            reason: "Wallpaper started"
        )

        hasWallpaper = true

        statusMessage =
            "Live wallpaper is active — " +
            "\(scalingMode.displayName)."
    }

    // MARK: - Remove Wallpaper

    private func removeWallpaper() {

        wallpaperManager.hideWallpaper()

        playbackController.pause()

        performanceController.handleManualPause()

        hasWallpaper = false

        statusMessage =
            "Wallpaper removed."
    }

    // MARK: - Remove Library Item

    private func removeLibraryItem(
        id: UUID
    ) {

        if wallpaperLibrary.selectedItemID == id {

            wallpaperManager.hideWallpaper()

            playbackController.unloadVideo()

            hasWallpaper = false

            metadata = nil
        }

        wallpaperLibrary.removeWallpaper(
            id: id
        )

        selectedItemID =
            wallpaperLibrary.selectedItemID

        if let newSelectedID =
                wallpaperLibrary.selectedItemID {

            Task { @MainActor in

                selectWallpaper(
                    id: newSelectedID
                )
            }

        } else {

            statusMessage =
                "Wallpaper removed from library."
        }
    }

    // MARK: - Duration Formatting

    private func formatDuration(
        _ seconds: Double
    ) -> String {

        guard seconds.isFinite,
              seconds >= 0
        else {

            return "--:--"
        }

        let totalSeconds =
            Int(seconds.rounded())

        let minutes =
            totalSeconds / 60

        let remainingSeconds =
            totalSeconds % 60

        return String(
            format: "%02d:%02d",
            minutes,
            remainingSeconds
        )
    }
}

// MARK: - Settings Placeholder

struct SettingsView: View {

    var body: some View {

        VStack(spacing: 16) {

            Text("Settings")
                .font(.title)

            Text(
                "Settings will be expanded in Stage 13."
            )
            .foregroundStyle(.secondary)
        }
        .frame(
            width: 500,
            height: 300
        )
        .padding()
    }
}
