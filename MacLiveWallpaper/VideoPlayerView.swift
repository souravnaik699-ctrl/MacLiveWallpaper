//
//  VideoPlayerView.swift
//  MacLiveWallpaper
//
//  Created by SOURAV NAIK on 01/10/26.
//

import SwiftUI
import AppKit
import AVFoundation

struct VideoPlayerView: NSViewRepresentable {

    let player: AVPlayer?

    func makeNSView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.player = player
        return view
    }

    func updateNSView(_ nsView: PlayerContainerView, context: Context) {
        nsView.playerLayer.player = player
    }

    static func dismantleNSView(
        _ nsView: PlayerContainerView,
        coordinator: ()
    ) {
        nsView.playerLayer.player = nil
    }
}


// MARK: - Player Container View

final class PlayerContainerView: NSView {

    let playerLayer = AVPlayerLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        wantsLayer = true

        playerLayer.videoGravity = .resizeAspect
        layer?.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        wantsLayer = true

        playerLayer.videoGravity = .resizeAspect
        layer?.addSublayer(playerLayer)
    }

    override func layout() {
        super.layout()

        playerLayer.frame = bounds
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        playerLayer.frame = bounds
    }
}
