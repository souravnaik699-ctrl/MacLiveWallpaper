//
//  DisplayManager.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//

//import AppKit
//import Combine
//import CoreGraphics
//import OSLog
//
//@MainActor
//final class DisplayManager: ObservableObject {
//
//    // MARK: - Published Properties
//
//    @Published private(set) var displays: [DisplayInfo] = []
//
//    // MARK: - Private Properties
//
//    private var displayChangeTask: Task<Void, Never>?
//
//    private let logger = Logger(
//        subsystem: Bundle.main.bundleIdentifier ?? "MacLiveWallpaper",
//        category: "DisplayManager"
//    )
//
//    // MARK: - Initialization
//
//    init() {
//        refreshDisplays()
//        startObservingDisplayChanges()
//    }
//
//    deinit {
//        displayChangeTask?.cancel()
//    }
//
//    // MARK: - Display Management
//
//    func refreshDisplays() {
//        let screens = NSScreen.screens
//
//        displays = screens.map { screen in
//            DisplayInfo(screen: screen)
//        }
//
//        logger.info(
//            "Display list refreshed: \(self.displays.count) display(s)"
//        )
//    }
//
//    // MARK: - Display Change Observation
//
//    private func startObservingDisplayChanges() {
//
//        displayChangeTask = Task { @MainActor [weak self] in
//
//            guard let self else {
//                return
//            }
//
//            let notifications = NotificationCenter.default.notifications(
//                named: NSApplication.didChangeScreenParametersNotification
//            )
//
//            for await _ in notifications {
//                guard !Task.isCancelled else {
//                    break
//                }
//                try? await Task.sleep(for:.milliseconds(150))
//                self.refreshDisplays()
//            }
//        }
//    }
//
//    // MARK: - Helper Methods
//
//    func display(withID id: CGDirectDisplayID) -> DisplayInfo? {
//        displays.first { display in
//            display.id == id
//        }
//    }
//
//    func mainDisplay() -> DisplayInfo? {
//        displays.first { display in
//            display.isMain
//        }
//    }
//
//    var displayCount: Int {
//        displays.count
//    }
//}



import AppKit
import Combine
import CoreGraphics
import OSLog

@MainActor
final class DisplayManager: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var displays:
        [DisplayInfo] = []

    // MARK: - Private State

    private var displayChangeTask:
        Task<Void, Never>?

    private let logger =
        Logger(
            subsystem:
                Bundle.main.bundleIdentifier
                ?? "MacLiveWallpaper",
            category: "DisplayManager"
        )

    // MARK: - Initialization

    init() {

        refreshDisplays()
        startObservingDisplayChanges()
    }

    // MARK: - Deinitialization

    deinit {

        displayChangeTask?.cancel()
    }

    // MARK: - Refresh

    func refreshDisplays() {

        let screens =
            NSScreen.screens

        displays =
            screens.map {
                DisplayInfo(
                    screen: $0
                )
            }

        logger.info(
            "Display list refreshed: \(self.displays.count) display(s)"
        )
    }

    // MARK: - Display Change Observation

    private func startObservingDisplayChanges() {

        displayChangeTask =
            Task { @MainActor [weak self] in

                let notifications =
                    NotificationCenter.default.notifications(
                        named:
                            NSApplication
                            .didChangeScreenParametersNotification
                    )

                for await _ in notifications {

                    guard
                        !Task.isCancelled
                    else {
                        break
                    }

                    guard let self else {
                        break
                    }

                    self.refreshDisplays()
                }
            }
    }

    // MARK: - Helpers

    func display(
        withID id: CGDirectDisplayID
    ) -> DisplayInfo? {

        displays.first {
            $0.id == id
        }
    }

    func mainDisplay() -> DisplayInfo? {

        displays.first {
            $0.isMain
        }
    }

    var displayCount: Int {

        displays.count
    }
}
