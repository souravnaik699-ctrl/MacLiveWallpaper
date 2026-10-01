//
//  VideoPlayerView.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//

//import SwiftUI
//import AppKit
//import AVFoundation
//
//// MARK: - SwiftUI Video Player View
//
//struct VideoPlayerView: NSViewRepresentable {
//
//    let player: AVPlayer?
//    var scalingMode: VideoScalingMode = .fill
//
//    // MARK: Create NSView
//
//    func makeNSView(context: Context) -> PlayerContainerView {
//
//        let view = PlayerContainerView()
//
//        view.scalingMode = scalingMode
//        view.playerLayer.player = player
//
//        return view
//    }
//
//    // MARK: Update NSView
//
//    func updateNSView(
//        _ nsView: PlayerContainerView,
//        context: Context
//    ) {
//
//        nsView.scalingMode = scalingMode
//        nsView.playerLayer.player = player
//
//        nsView.updateVideoLayout()
//    }
//}
//
//
//// MARK: - Player Container View
//
//final class PlayerContainerView: NSView {
//
//    // AVPlayerLayer displays the video.
//    let playerLayer = AVPlayerLayer()
//
//    // Current scaling mode.
//    var scalingMode: VideoScalingMode = .fill {
//        didSet {
//            updateVideoLayout()
//        }
//    }
//
//    // MARK: Initializer
//
//    override init(frame frameRect: NSRect) {
//
//        super.init(frame: frameRect)
//
//        setupView()
//    }
//
//    // MARK: Storyboard / Nib Initializer
//
//    required init?(coder: NSCoder) {
//
//        super.init(coder: coder)
//
//        setupView()
//    }
//
//    // MARK: Setup
//
//    private func setupView() {
//
//        wantsLayer = true
//
//        layer?.backgroundColor = NSColor.black.cgColor
//
//        playerLayer.videoGravity = .resizeAspectFill
//
//        layer?.addSublayer(playerLayer)
//    }
//
//    // MARK: Layout
//
//    override func layout() {
//
//        super.layout()
//
//        updateVideoLayout()
//    }
//
//    // MARK: Update Video Layout
//
//    func updateVideoLayout() {
//
//        guard bounds.width > 0,
//              bounds.height > 0 else {
//            return
//        }
//
//        switch scalingMode {
//
//        // ---------------------------------------------------------
//        // FILL
//        // ---------------------------------------------------------
//
//        case .fill:
//
//            playerLayer.videoGravity = .resizeAspectFill
//
//            playerLayer.frame = bounds
//
//
//        // ---------------------------------------------------------
//        // FIT
//        // ---------------------------------------------------------
//
//        case .fit:
//
//            playerLayer.videoGravity = .resizeAspect
//
//            playerLayer.frame = bounds
//
//
//        // ---------------------------------------------------------
//        // CENTER
//        // ---------------------------------------------------------
//
//        case .center:
//
//            playerLayer.videoGravity = .resizeAspect
//
//            playerLayer.frame = centeredVideoFrame()
//        }
//    }
//
//    // MARK: Center Video
//
//    private func centeredVideoFrame() -> CGRect {
//
//        // IMPORTANT:
//        // The player belongs to AVPlayerLayer.
//        // Therefore we access it through:
//        //
//        // playerLayer.player
//        //
//        // This fixes:
//        // "Cannot find 'player' in scope"
//
//        guard let player = playerLayer.player,
//              let currentItem = player.currentItem else {
//
//            return bounds
//        }
//
//        // Get the video's presentation size.
//        let videoSize = currentItem.presentationSize
//
//        guard videoSize.width > 0,
//              videoSize.height > 0 else {
//
//            return bounds
//        }
//
//        // Calculate the scale required to keep
//        // the complete video inside the available area.
//        //
//        // min() ensures that the video fits both:
//        // - width
//        // - height
//
//        let scale = min(
//            1.0,
//            min(
//                bounds.width / videoSize.width,
//                bounds.height / videoSize.height
//            )
//        )
//
//        let width = videoSize.width * scale
//        let height = videoSize.height * scale
//
//        // Calculate the position required
//        // to place the video in the center.
//
//        let x = (bounds.width - width) / 2.0
//        let y = (bounds.height - height) / 2.0
//
//        return CGRect(
//            x: x,
//            y: y,
//            width: width,
//            height: height
//        )
//    }
//}



import SwiftUI
import AppKit
import AVFoundation

// MARK: - SwiftUI Video Player View

struct VideoPlayerView: NSViewRepresentable {

    let player: AVPlayer?
    var scalingMode: VideoScalingMode = .fill

    // MARK: Create NSView

    func makeNSView(
        context: Context
    ) -> PlayerContainerView {

        let view = PlayerContainerView()

        view.scalingMode = scalingMode
        view.bind(player: player)

        return view
    }

    // MARK: Update NSView

    func updateNSView(
        _ nsView: PlayerContainerView,
        context: Context
    ) {

        nsView.scalingMode = scalingMode
        nsView.bind(player: player)
        nsView.updateVideoLayout()
    }

    // MARK: Dismantle NSView

    static func dismantleNSView(
        _ nsView: PlayerContainerView,
        coordinator: ()
    ) {
        // Detach the visual layer from the shared player.
        //
        // IMPORTANT:
        // We do NOT pause or destroy the AVPlayer here.
        // The same AVPlayer may be reused by another wallpaper window.
        nsView.unbindPlayer()
    }
}


// MARK: - Player Container View

final class PlayerContainerView: NSView {

    // The AVPlayerLayer displays the video.
    let playerLayer = AVPlayerLayer()

    // Current scaling mode.
    var scalingMode: VideoScalingMode = .fill {
        didSet {
            updateVideoLayout()
        }
    }

    // MARK: Initializer

    override init(frame frameRect: NSRect) {

        super.init(frame: frameRect)

        setupView()
    }

    // MARK: Storyboard / Nib Initializer

    required init?(coder: NSCoder) {

        super.init(coder: coder)

        setupView()
    }

    // MARK: Setup

    private func setupView() {

        wantsLayer = true

        layer?.backgroundColor =
            NSColor.black.cgColor

        playerLayer.videoGravity =
            .resizeAspectFill

        playerLayer.needsDisplayOnBoundsChange = true

        layer?.addSublayer(playerLayer)
    }

    // MARK: Window Binding

    override func viewDidMoveToWindow() {

        super.viewDidMoveToWindow()

        // A wallpaper view can move into a newly-created
        // NSWindow after a display configuration change.
        //
        // Rebind the player whenever that happens.

        if window != nil {

            playerLayer.player =
                playerLayer.player

            updateVideoLayout()

            layer?.layoutIfNeeded()
            playerLayer.setNeedsLayout()
            playerLayer.setNeedsDisplay()
        }
    }

    // MARK: Layout

    override func layout() {

        super.layout()

        updateVideoLayout()
    }

    // MARK: Bind Player

    func bind(player: AVPlayer?) {

        playerLayer.player = player

        updateVideoLayout()

        playerLayer.setNeedsDisplay()
    }

    // MARK: Unbind Player

    func unbindPlayer() {

        playerLayer.player = nil
    }

    // MARK: Update Video Layout

    func updateVideoLayout() {

        guard bounds.width > 0,
              bounds.height > 0 else {
            return
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        switch scalingMode {

        // ---------------------------------------------------------
        // FILL
        // ---------------------------------------------------------

        case .fill:

            playerLayer.videoGravity =
                .resizeAspectFill

            playerLayer.frame = bounds


        // ---------------------------------------------------------
        // FIT
        // ---------------------------------------------------------

        case .fit:

            playerLayer.videoGravity =
                .resizeAspect

            playerLayer.frame = bounds


        // ---------------------------------------------------------
        // CENTER
        // ---------------------------------------------------------

        case .center:

            playerLayer.videoGravity =
                .resizeAspect

            playerLayer.frame =
                centeredVideoFrame()
        }

        CATransaction.commit()

        playerLayer.setNeedsLayout()
        playerLayer.setNeedsDisplay()
    }

    // MARK: Center Video

    private func centeredVideoFrame() -> CGRect {

        guard
            let player = playerLayer.player,
            let currentItem = player.currentItem
        else {
            return bounds
        }

        let videoSize =
            currentItem.presentationSize

        guard videoSize.width > 0,
              videoSize.height > 0
        else {
            return bounds
        }

        let scale = min(
            1.0,
            min(
                bounds.width / videoSize.width,
                bounds.height / videoSize.height
            )
        )

        let width =
            videoSize.width * scale

        let height =
            videoSize.height * scale

        let x =
            (bounds.width - width) / 2.0

        let y =
            (bounds.height - height) / 2.0

        return CGRect(
            x: x,
            y: y,
            width: width,
            height: height
        )
    }
}
