//
//  SystemPowerMonitor.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//

import Foundation
import Combine
import IOKit.ps
import OSLog

@MainActor
final class SystemPowerMonitor: ObservableObject {

    // MARK: - Published State

    @Published private(set) var isLowPowerModeEnabled: Bool
    @Published private(set) var thermalState: ProcessInfo.ThermalState
    @Published private(set) var batteryPercentage: Int?
    @Published private(set) var isUsingBatteryPower: Bool

    // MARK: - Private Properties

    private var observers: [NSObjectProtocol] = []

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "MacLiveWallpaper",
        category: "PowerMonitor"
    )

    // MARK: - Initialization

    init() {
        let processInfo = ProcessInfo.processInfo

        self.isLowPowerModeEnabled =
            processInfo.isLowPowerModeEnabled

        self.thermalState =
            processInfo.thermalState

        self.batteryPercentage = nil
        self.isUsingBatteryPower = false

        refreshBatteryInformation()
        installObservers()

        logger.info("System power monitor initialized.")
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Notifications

    private func installObservers() {

        let powerObserver = NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: ProcessInfo.processInfo,
            queue: .main
        ) { [weak self] _ in

            Task { @MainActor [weak self] in
                guard let self else { return }

                self.isLowPowerModeEnabled =
                    ProcessInfo.processInfo.isLowPowerModeEnabled

                self.refreshBatteryInformation()

                self.logger.info(
                    "Power state changed. Low Power Mode: \(self.isLowPowerModeEnabled)"
                )
            }
        }

        let thermalObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: ProcessInfo.processInfo,
            queue: .main
        ) { [weak self] _ in

            Task { @MainActor [weak self] in
                guard let self else { return }

                self.thermalState =
                    ProcessInfo.processInfo.thermalState

                self.logger.info(
                    "Thermal state changed: \(String(describing: self.thermalState))"
                )
            }
        }

        observers = [
            powerObserver,
            thermalObserver
        ]

        logger.info("Power and thermal observers installed.")
    }

    // MARK: - Battery Information

    private func refreshBatteryInformation() {

        guard let powerSourcesInfo =
                IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        else {
            batteryPercentage = nil
            isUsingBatteryPower = false

            logger.warning(
                "Unable to read power source information."
            )

            return
        }

        let powerSourcesList =
            IOPSCopyPowerSourcesList(powerSourcesInfo)
                .takeRetainedValue()

        let sourceCount =
            CFArrayGetCount(powerSourcesList)

        var detectedBatteryPercentage: Int?
        var detectedBatteryPower = false

        for index in 0..<sourceCount {

            let source =
                CFArrayGetValueAtIndex(
                    powerSourcesList,
                    index
                )

            guard let source else {
                continue
            }

            let sourceRef =
                unsafeBitCast(
                    source,
                    to: CFTypeRef.self
                )

            guard let description =
                    IOPSGetPowerSourceDescription(
                        powerSourcesInfo,
                        sourceRef
                    )?.takeUnretainedValue()
                    as? [String: Any]
            else {
                continue
            }

            guard let powerSourceState =
                    description[
                        kIOPSPowerSourceStateKey as String
                    ] as? String
            else {
                continue
            }

            if powerSourceState == kIOPSBatteryPowerValue {

                detectedBatteryPower = true

                if let currentCapacity =
                    description[
                        kIOPSCurrentCapacityKey as String
                    ] as? Int,

                   let maximumCapacity =
                    description[
                        kIOPSMaxCapacityKey as String
                    ] as? Int,

                   maximumCapacity > 0 {

                    let percentage =
                        (Double(currentCapacity)
                        / Double(maximumCapacity)) * 100.0

                    detectedBatteryPercentage =
                        max(
                            0,
                            min(
                                100,
                                Int(percentage.rounded())
                            )
                        )
                }
            }
        }

        batteryPercentage = detectedBatteryPercentage
        isUsingBatteryPower = detectedBatteryPower

        logger.debug(
            "Battery: \(self.batteryPercentage ?? -1)%, On battery: \(self.isUsingBatteryPower)"
        )
    }
}
