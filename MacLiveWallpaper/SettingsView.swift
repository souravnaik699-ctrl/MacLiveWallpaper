//
//  SettingsView.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 02/10/26.
//


import SwiftUI

struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss

    private enum SettingsTab: String, CaseIterable, Identifiable {

        case general
        case playback
        case appearance
        case performance

        var id: String {
            rawValue
        }

        var title: String {
            switch self {
            case .general:
                return "General"

            case .playback:
                return "Playback"

            case .appearance:
                return "Appearance"

            case .performance:
                return "Performance"
            }
        }

        var icon: String {
            switch self {
            case .general:
                return "gear"

            case .playback:
                return "play.fill"

            case .appearance:
                return "rectangle.inset.filled"

            case .performance:
                return "battery.100percent"
            }
        }
    }

    @State private var selectedTab: SettingsTab = .general

    var body: some View {

        VStack(spacing: 0) {

            // MARK: - TOP BAR

            HStack {

                Button {
                    dismiss()
                } label: {
                    Label(
                        "Library",
                        systemImage: "chevron.left"
                    )
                }
                .buttonStyle(.borderless)

                Spacer()

                Text("Settings")
                    .font(.headline)

                Spacer()

                Color.clear
                    .frame(width: 70)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()

            // MARK: - SETTINGS TABS

            Picker(
                "Settings",
                selection: $selectedTab
            ) {

                ForEach(SettingsTab.allCases) { tab in

                    Label(
                        tab.title,
                        systemImage: tab.icon
                    )
                    .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()

            // MARK: - SETTINGS CONTENT

            Group {

                switch selectedTab {

                case .general:
                    GeneralSettingsView()

                case .playback:
                    PlaybackSettingsView()

                case .appearance:
                    AppearanceSettingsView()

                case .performance:
                    PerformanceSettingsView()
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
        .frame(
            minWidth: 650,
            minHeight: 430
        )
    }
}
