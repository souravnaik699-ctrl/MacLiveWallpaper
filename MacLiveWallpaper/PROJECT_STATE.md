# MAC LIVE WALLPAPER — PROJECT STATE

## Project

**Working name:** MAC LIVE WALLPAPER
**Current version:** 0.1
**Current stage:** Stage 4 — Video Preview
**Status:** Stage 4 complete after testing and Git commit

---

# Environment

* Mac: MacBook Air, Apple Silicon M5
* macOS: macOS 27
* Xcode: Xcode 27.0
* Swift: Swift 6.4
* Minimum supported macOS: macOS 14
* External monitor testing: iPad used as external monitor
* Primary architecture: Apple Silicon / arm64

---

# Technology Stack

* Swift
* SwiftUI
* AppKit
* AVFoundation
* UniformTypeIdentifiers
* Foundation
* OSLog
* Core Animation
* Codable / UserDefaults planned
* SMAppService planned
* Public Apple APIs only
* No third-party dependencies

---

# Architecture Decisions

## App Lifecycle

Normal macOS application during development.

Menu-bar functionality will be added later.

`LSUIElement` is not currently enabled.

## Minimum macOS

macOS 14 Sonoma.

## File Access

Security-scoped bookmarks are used.

The original user video is not copied or modified.

User-selected file access is read-only.

---

# Stage 3 Implementation

Implemented:

* NSOpenPanel
* MP4/MOV filtering
* File validation
* Security-scoped access
* Security-scoped bookmark creation
* AVFoundation metadata loading
* Resolution detection
* Duration detection
* Codec detection
* Import error handling
* OSLog logging

---

# Stage 4 Implementation

## VideoPlayerController.swift

Responsible for:

* Creating AVPlayer
* Loading selected video
* Playing
* Pausing
* Stopping
* Restarting
* Temporary basic looping
* Playback failure handling
* Security-scoped access during playback
* Releasing security-scoped access
* Playback logging

## VideoPlayerView.swift

Responsible for:

* Bridging AppKit into SwiftUI using NSViewRepresentable
* Creating an AppKit NSView
* Creating AVPlayerLayer
* Connecting AVPlayer to AVPlayerLayer
* Displaying the video
* Maintaining the preview aspect ratio

## ContentView.swift

Responsible for:

* Main interface
* Video import button
* Video preview
* Metadata display
* Playback controls
* Status information
* Settings placeholder
* Remove functionality

---

# Current Video Playback Architecture

```text
SwiftUI ContentView
        │
        ▼
VideoPlayerController
        │
        ▼
AVPlayer
        │
        ▼
VideoPlayerView
        │
        ▼
NSView
        │
        ▼
AVPlayerLayer
        │
        ▼
Video
```

---

# Current Playback Features

* [x] Load local MP4
* [x] Load local MOV
* [x] Video preview
* [x] Play
* [x] Pause
* [x] Stop
* [x] Restart
* [x] Basic looping
* [x] Playback error handling
* [x] Logging
* [x] Security-scoped access during playback
* [x] Release security-scoped access

---

# Looping Decision

Stage 4 uses basic end-of-item detection:

```text
Video ends
   ↓
seek to zero
   ↓
play
```

This is NOT considered the final seamless looping implementation.

## Planned Stage 8 implementation

Use:

```text
AVQueuePlayer
+
AVPlayerLooper
```

for production looping.

The basic Stage 4 loop may have a visible transition/stutter.

---

# Current Video Scaling

Current preview uses:

```text
AVLayerVideoGravity.resizeAspect
```

This keeps the video's aspect ratio and fits the whole video inside the preview.

Final:

* Fill
* Fit
* Center

behavior will be implemented in Stage 6.

---

# Implemented

* [x] Stage 1 project setup
* [x] Git
* [x] GitHub
* [x] Xcode `.gitignore`
* [x] PROJECT_STATE.md
* [x] Stage 2 SwiftUI interface
* [x] Stage 3 video import
* [x] Stage 3 metadata
* [x] Security-scoped bookmarks
* [x] Stage 4 AVPlayer
* [x] Stage 4 AVPlayerLayer
* [x] Stage 4 video preview
* [x] Play
* [x] Pause
* [x] Stop
* [x] Restart
* [x] Basic looping
* [x] Playback error handling
* [x] Playback logging

---

# Not Implemented

* Seamless AVPlayerLooper
* Audio controls
* Wallpaper window
* Desktop integration
* Desktop-level window
* All Spaces
* Full-screen wallpaper
* Fill/Fit/Center final implementation
* Wallpaper library
* Persistent wallpaper model
* Multiple displays
* Menu bar
* Performance modes
* Smart pausing
* Battery optimization
* Start at Login
* Static wallpaper fallback
* Lock Screen integration
* Relink workflow
* Complete Settings
* Release signing
* Notarization
* Packaging
* Final app name

---

# Known Limitations

1. Stage 4 uses a basic seek-and-replay loop.
2. The loop may have a small visible transition.
3. The final seamless loop will be implemented in Stage 8.
4. The current selected bookmark is not yet persisted into the final wallpaper library.
5. The current video is only a preview; it is not yet a desktop wallpaper.

---

# Next Stage

## Stage 5 — Wallpaper Engine

Planned:

* AppKit wallpaper window
* Borderless window
* Correct display frame
* Desktop-level window behavior
* Ignore mouse events
* Video playback inside wallpaper window
* Connect "Set Wallpaper"
* Explain NSWindow.Level
* Explain NSWindow.collectionBehavior
* Explain limitations around Spaces/full-screen applications
* Keep normal application UI separate from wallpaper window

Do not begin Stage 5 until Stage 4 is confirmed working.

