//
//  PerformanceSettingsView.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 02/10/26.
//

import SwiftUI

struct PerformanceSettingsView: View {

    private let performanceModes = [
        "Quality",
        "Balanced",
        "Battery Saver"
    ]

    @AppStorage(
        AppSettings.performanceMode
    )
    private var performanceMode = "Balanced"

    @AppStorage(
        AppSettings.pauseOnBattery
    )
    private var pauseOnBattery = false

    @AppStorage(
        AppSettings.pauseOnLowPowerMode
    )
    private var pauseOnLowPowerMode = true

    @AppStorage(
        AppSettings.batteryThreshold
    )
    private var batteryThreshold = 20

    var body: some View {

        Form {

            Section {

                Picker(
                    "Performance Mode",
                    selection: $performanceMode
                ) {

                    ForEach(
                        performanceModes,
                        id: \.self
                    ) { mode in

                        Text(mode)
                            .tag(mode)
                    }
                }

            } header: {

                Text("Performance")
            }

            Section {

                Toggle(
                    "Pause on Battery",
                    isOn: $pauseOnBattery
                )

                Toggle(
                    "Pause in Low Power Mode",
                    isOn: $pauseOnLowPowerMode
                )

                Stepper(
                    "Battery Threshold: \(batteryThreshold)%",
                    value: $batteryThreshold,
                    in: 5...50,
                    step: 5
                )

            } header: {

                Text("Battery")
            }

            Section {

                Text(
                    "Battery and performance controls will be connected to the wallpaper performance controller in the performance stage."
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
