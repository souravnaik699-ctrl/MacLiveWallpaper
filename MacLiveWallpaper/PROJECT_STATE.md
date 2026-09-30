# MAC LIVE WALLPAPER — PROJECT STATE

## Project

**Working name:** MAC LIVE WALLPAPER
**Current version:** 0.1
**Current stage:** Stage 3 — Video Import
**Status:** Stage 3 complete after testing and Git commit

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

* Swift
* SwiftUI
* AppKit
* AVFoundation
* UniformTypeIdentifiers
* Foundation
* OSLog
* Codable / UserDefaults planned
* SMAppService planned
* Public Apple APIs only
* No third-party dependencies

---

# Stage 1 Decisions

## App Lifecycle

Normal macOS application with Dock presence during development.

Menu-bar functionality will be added later.

`LSUIElement` is not currently enabled.

## Minimum macOS

macOS 14 Sonoma.

## Architecture

Apple Silicon / arm64 primary development target.

---

# Stage 3 File Access Decision

## Decision

**Use security-scoped bookmarks to access the user's original video files.**

The application does NOT copy the user's videos into its own storage.

## Reason

Advantages:

* Preserves the user's original video.
* Avoids unnecessary duplication of potentially large 4K files.
* Avoids unnecessary disk usage.
* Allows the application to retain access to the original file through a security-scoped bookmark.
* Fits the requirement that the original video remains untouched.

Tradeoff:

* If the user moves or deletes the original file, the app may lose access.
* The future wallpaper library must detect unavailable files and provide a relink/reselect workflow.

## Bookmark policy

Bookmarks are created with:

* Security scope
* Read-only access

The application must balance:

`startAccessingSecurityScopedResource()`

with:

`stopAccessingSecurityScopedResource()`

---

# Stage 3 App Sandbox

App Sandbox is enabled.

User-selected file access:

**Read Only**

The application does not request read/write access to the user's original video files.

No all-files entitlement is used.

No network entitlement is required.

---

# Stage 3 Implementation

## VideoImportService.swift

Responsible for:

* NSOpenPanel
* MP4/MOV filtering
* File-extension validation
* Security-scoped access
* Security-scoped bookmark creation
* AVFoundation metadata loading
* Codec detection
* Resolution detection
* Duration detection
* Error handling
* OSLog logging

## ContentView.swift

Now displays real imported video metadata.

Current UI state includes:

* Selected video filename
* Resolution
* Codec
* Duration
* Importing state
* Status message
* Bookmark data held in memory

---

# Supported Video Types

Current UI selection:

* MP4
* MOV

Uniform Type Identifiers used:

* `UTType.mpeg4Movie`
* `UTType.quickTimeMovie`

The app also checks the filename extension.

---

# Metadata Currently Read

For the first video track:

* Filename
* Duration
* Natural width
* Natural height
* Codec

Example:

```text
wallpaper.mp4
1920 × 1080
H.264
0:15
```

---

# Important Current Limitation

The application can select and inspect videos, but it does NOT play them yet.

There is currently:

* No AVPlayer
* No AVPlayerLayer
* No video preview playback
* No wallpaper window
* No desktop integration

These belong to later stages.

---

# Current Architecture

```text
SwiftUI
   │
   ▼
ContentView
   │
   │ Add Wallpaper
   ▼
VideoImportService
   │
   ├── NSOpenPanel
   │
   ├── Security-scoped bookmark
   │
   └── AVFoundation
          │
          ├── Duration
          ├── Resolution
          └── Codec
```

---

# Implemented

* [x] Stage 1 project setup
* [x] Git repository
* [x] GitHub repository
* [x] `.gitignore`
* [x] PROJECT_STATE.md
* [x] v0.1
* [x] Stage 2 SwiftUI interface
* [x] App Sandbox
* [x] User Selected File — Read Only
* [x] NSOpenPanel
* [x] MP4 selection
* [x] MOV selection
* [x] Security-scoped bookmark creation
* [x] Security-scoped resource access
* [x] Video validation
* [x] AVFoundation asset creation
* [x] Duration detection
* [x] Resolution detection
* [x] Codec detection
* [x] Import error handling
* [x] OSLog logging

---

# Not Implemented

* AVPlayer
* AVPlayerLayer / SwiftUI video rendering
* Video playback
* Play/Pause functionality
* Seamless looping
* Audio controls
* Wallpaper window
* Desktop integration
* Full-screen wallpaper
* Fill/Fit/Center
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
* Relink workflow for missing files
* Final Settings
* Release signing
* Notarization
* Packaging
* Final name

---

# Known Bugs

None known if the Stage 3 checklist passes.

Potential future condition:

A bookmark may become stale or fail if the original file is moved/deleted. A future library/relink workflow must handle this gracefully.

---

# Version

Current development version:

**v0.1**

---

# Next Stage

## Stage 4 — Video Preview

Planned:

* AVPlayer
* Video rendering in SwiftUI
* Play
* Pause
* Stop
* Real video preview
* Playback error handling

Do not begin Stage 4 until Stage 3 is confirmed working.
