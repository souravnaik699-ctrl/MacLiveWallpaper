
# MAC LIVE WALLPAPER — PROJECT STATE

## Project

**Working name:** MAC LIVE WALLPAPER
**Current version:** 0.1
**Current stage:** Stage 2 — Basic SwiftUI Interface
**Status:** Stage 2 complete after testing and Git commit

---

## Environment

* Mac: MacBook Air, Apple Silicon M5
* macOS: macOS 27
* Xcode: Xcode 27.0
* Swift: Swift 6.4
* Minimum supported macOS: macOS 14
* External monitor testing: iPad used as external monitor
* Primary architecture: Apple Silicon / arm64

---

## Technology Stack

* Language: Swift
* UI: SwiftUI
* macOS integration: AppKit
* Video: AVFoundation
* Login item: SMAppService
* Persistence: Codable / UserDefaults
* Logging: OSLog / os.Logger
* Public Apple APIs only
* No third-party dependencies currently

---

## Stage 1 Decisions

### App lifecycle

Normal macOS application with a Dock presence during initial development, with menu-bar functionality to be added later.

`LSUIElement` is not enabled at this stage.

### Minimum macOS version

macOS 14 Sonoma.

### Architecture

Apple Silicon / arm64 as the primary development architecture.

### File access

Not decided yet.

This decision must be made before Stage 3.

### Audio

Muted by default is planned. Audio controls are not implemented yet.

### Looping

AVQueuePlayer + AVPlayerLooper planned for a later stage.

### Desktop integration

Not implemented yet.

### Static wallpaper fallback

Not implemented yet.

---

## Stage 2 Implementation

### Main interface

Implemented a basic SwiftUI interface containing:

* MAC LIVE WALLPAPER title
* Subtitle
* Current wallpaper preview area
* Add Wallpaper button
* Set Wallpaper button
* Play button
* Pause button
* Remove button
* Settings button
* Status indicator/message

### Settings

Added a temporary SwiftUI Settings sheet.

The Settings UI is only a placeholder at this stage. Full settings are planned for Stage 13.

### UI state

The interface currently uses local SwiftUI `@State` values for:

* Wallpaper selection state
* Playback state
* Status message
* Settings sheet visibility

### Important Stage 2 limitation

The controls are UI placeholders.

No real video file is imported yet.

No AVPlayer exists yet.

No wallpaper window exists yet.

No desktop wallpaper is changed yet.

Real video importing begins in Stage 3.

---

## Current Architecture

```text
MacLiveWallpaper/
│
├── MacLiveWallpaper.xcodeproj
│
├── MacLiveWallpaper/
│   ├── MacLiveWallpaperApp.swift
│   ├── ContentView.swift
│   └── Assets.xcassets
│
├── .gitignore
└── PROJECT_STATE.md
```

---

## Current Files

### MacLiveWallpaperApp.swift

Application entry point.

### ContentView.swift

Current main SwiftUI interface and temporary Settings view.

### Assets.xcassets

Application asset catalog.

### .gitignore

Xcode/Git generated-file exclusions.

### PROJECT_STATE.md

Project continuity and source-of-truth document.

---

## Implemented

* [x] Stage 1 project setup
* [x] SwiftUI macOS application
* [x] macOS 14 minimum target
* [x] Apple Silicon development target
* [x] Git repository
* [x] GitHub repository
* [x] `.gitignore`
* [x] `PROJECT_STATE.md`
* [x] v0.1 tag
* [x] Main SwiftUI interface
* [x] Add Wallpaper UI action
* [x] Preview placeholder
* [x] Set Wallpaper UI action
* [x] Play UI action
* [x] Pause UI action
* [x] Remove UI action
* [x] Temporary Settings sheet

---

## Not Implemented

* Video importing
* NSOpenPanel
* MP4/MOV validation
* Security-scoped bookmarks
* Application Support video storage
* Video metadata
* Codec detection
* AVPlayer
* AVPlayerLooper
* Actual video preview
* Wallpaper window
* Desktop integration
* Full-screen wallpaper
* Fill/Fit/Center
* Wallpaper library
* Multiple displays
* Menu-bar controls
* Audio controls
* Performance modes
* Smart pausing
* Battery optimization
* Start at Login
* Static wallpaper fallback
* Lock Screen integration
* Final Settings
* Error handling for video files
* Release signing
* Notarization
* Packaging
* Final application name

---

## Known Bugs

None known if the Stage 2 checklist passes.

---

## Version

Current development version:

**v0.1**

Stage 2 is still part of the initial v0.1 foundation.

---

## Next Stage

**Stage 3 — Video Import**

Stage 3 will introduce:

* NSOpenPanel
* MP4/MOV file selection
* File validation
* File-access architecture decision
* Permission handling
* Video metadata
* Codec/resolution information

Do not begin Stage 3 until Stage 2 is confirmed working.
