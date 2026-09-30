# ## Stage 5 — macOS Wallpaper Engine

Implemented:
- WallpaperWindowManager
- Borderless wallpaper NSWindow
- One wallpaper window per connected display
- Desktop window level
- Mouse-event passthrough
- Spaces support
- Mission Control stationary behavior
- SwiftUI VideoPlayerView embedded into AppKit wallpaper windows
- Set Wallpaper connected to wallpaper engine
- Remove Wallpaper connected to wallpaper engine
- Wallpaper continues independently from main UI window

Architecture:
SwiftUI
    ↓
VideoPlayerController
    ↓
AVPlayer
    ↓
WallpaperWindowManager
    ↓
NSWindow per display
    ↓
NSHostingView
    ↓
VideoPlayerView
    ↓
AVPlayerLayer

Important decisions:
- Public macOS APIs only
- No private WindowServer APIs
- Wallpaper uses the documented desktop window level
- Uses NSScreen.screens for connected displays
- Uses screen.frame for complete display coverage
- Wallpaper windows ignore mouse events
- Wallpaper windows join all Spaces
- Different wallpapers per display are NOT implemented yet

Known limitations:
- Final Fill/Fit/Center behavior is Stage 6
- Seamless AVPlayerLooper looping is Stage 8
- Battery optimization is Stage 9
- Advanced per-display wallpaper selection is Stage 10
- Full Lock Screen replacement is not supported
- True full-screen application behavior depends on macOS Spaces/window-management rules
