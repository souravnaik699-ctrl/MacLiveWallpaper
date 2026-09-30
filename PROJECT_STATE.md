MAC LIVE WALLPAPER — PROJECT STATE
Project
Working name: MAC LIVE WALLPAPER Current version: 0.1 Current stage: Stage 1 — Project Setup Status: Stage 1 in progress

Environment
	•	Mac: MacBook Air, Apple Silicon M5
	•	macOS: macOS 27
	•	Xcode: Xcode 27.0
	•	Swift: Swift 6.4
	•	Minimum supported macOS: macOS 14
	•	External monitor testing: iPad used as external monitor
	•	Primary architecture: Apple Silicon / arm64

Technology Stack
	•	Language: Swift
	•	UI: SwiftUI
	•	macOS integration: AppKit
	•	Video: AVFoundation
	•	Login item: SMAppService
	•	Persistence: Codable / UserDefaults
	•	Logging: OSLog / os.Logger
	•	Public Apple APIs only
	•	No third-party dependencies currently

Stage 1 Decisions
App lifecycle
Decision:
Normal macOS application with a Dock presence during initial development, with menu-bar functionality to be added later.
Reason:
	•	Easier for a beginner to develop and debug.
	•	Allows a normal main application window.
	•	Wallpaper engine can later continue independently of the main window.
	•	Avoids prematurely making the application a menu-bar-only agent.
	•	LSUIElement is not enabled at this stage.
Minimum macOS version
Decision:
macOS 14 Sonoma
Reason:
	•	Provides a modern baseline.
	•	Allows use of required modern macOS frameworks while retaining compatibility with older supported Macs.
	•	Every API used later must still be checked against macOS 14 availability.
Architecture
Primary development target:
Apple Silicon / arm64
Primary test machine:
MacBook Air M5
No custom architecture overrides have been added at Stage 1.
File access
Decision:
Not decided yet.
Will be decided before Stage 3.
Options:
	1	Security-scoped bookmarks to original user files.
	2	Copy videos into Application Support.
Audio
Decision:
Not implemented yet.
Planned behavior:
	•	Muted by default.
	•	Optional volume/mute setting later.
Looping
Decision:
Not implemented yet.
Planned implementation:
	•	AVQueuePlayer
	•	AVPlayerLooper
Desktop integration
Decision:
Not implemented yet.
Will be investigated before Stage 5 using public AppKit APIs.
Static wallpaper fallback
Decision:
Not implemented yet.
Will be investigated in Stage 14 using supported NSWorkspace desktop-image APIs.

Current Architecture
At Stage 1 the project is intentionally minimal:
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

Current Files
MacLiveWallpaperApp.swift
Application entry point created by the SwiftUI macOS App template.
ContentView.swift
Initial SwiftUI interface created by Xcode.
Assets.xcassets
Asset catalog created by Xcode.
.gitignore
Prevents generated Xcode files and other unnecessary local files from entering Git.
PROJECT_STATE.md
Source-of-truth project status document for continuing development in future conversations.

Implemented
	•	Xcode macOS App project created
	•	SwiftUI selected
	•	Swift selected
	•	Minimum macOS target planned as macOS 14
	•	Apple Silicon primary development target
	•	Git repository initialized
	•	Main branch configured as main
	•	.gitignore created
	•	PROJECT_STATE.md created
	•	First Git commit
	•	GitHub repository
	•	Version tag v0.1

Not Implemented
	•	Video importing
	•	MP4/MOV validation
	•	Video metadata
	•	AVPlayer playback
	•	AVPlayerLooper
	•	Wallpaper window
	•	Desktop integration
	•	Full-screen wallpaper
	•	Fill/Fit/Center
	•	Wallpaper library
	•	Multiple displays
	•	Menu-bar controls
	•	Settings
	•	Audio controls
	•	Performance modes
	•	Smart pausing
	•	Battery optimization
	•	Start at Login
	•	Static wallpaper fallback
	•	Lock Screen integration
	•	Error handling for video files
	•	Release signing
	•	Notarization
	•	Packaging
	•	Final application name

Known Bugs
None known at the beginning of Stage 1.

Important Limitations
The application does not provide a video Lock Screen replacement.
Any future Lock Screen functionality must use supported public Apple APIs. No private APIs, security bypasses, system-file modifications, or authentication hacks will be used.

Development Workflow
Every stage follows:
Build
↓
Test
↓
Fix
↓
Commit
↓
Tag version
↓
Update PROJECT_STATE.md
↓
Stop
↓
User confirms
↓
Next stage

Version Plan
	•	v0.1 — Basic project / video player foundation
	•	v0.2 — Desktop wallpaper
	•	v0.3 — Wallpaper library
	•	v0.4 — Full-screen and scaling
	•	v0.5 — Menu-bar controls
	•	v0.6 — Multiple displays
	•	v0.7 — Performance optimization and smart pausing
	•	v0.8 — Settings, Start at Login, static fallback
	•	v0.9 — Testing and bug fixing
	•	v1.0 — Release

Current Stage Goal
Complete Stage 1 with:
	•	Working Xcode project
	•	Successful build and launch
	•	Git repository
	•	GitHub repository
	•	First commit
	•	v0.1 tag
	•	Updated PROJECT_STATE.md

Next Stage
Stage 2 — Basic SwiftUI Interface
Do not begin Stage 2 until Stage 1 is confirmed working.
