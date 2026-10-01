# ## Stage 10 — Multiple Display Support

Implemented:
- Display discovery
- Display information model
- Dynamic display configuration monitoring
- One wallpaper window per display
- One playback controller per display
- Different wallpaper per display
- Same wallpaper on all displays
- Display-specific wallpaper assignments
- Persistent display-to-wallpaper mapping
- Display connect handling
- Display disconnect handling
- Display resolution/position change handling
- Display information UI

Architecture:

NSScreen.screens
        ↓
DisplayManager
        ↓
MultiDisplayWallpaperManager
        ↓
DisplayWallpaper
        ↓
WallpaperWindowController
        ↓
VideoPlayerController
        ↓
AVQueuePlayer
        ↓
AVPlayerLooper

Persistence:

Display ID
    ↓
Wallpaper UUID
    ↓
DisplayWallpaperStore
    ↓
UserDefaults

Important decisions:
- Each display receives its own wallpaper window.
- Each display receives its own VideoPlayerController.
- Different displays can use different wallpapers.
- Original video files are never modified.
- NSScreen.frame is used for full-screen wallpaper geometry.
- NSScreen.visibleFrame is not used for wallpaper geometry.
- Public AppKit/CoreGraphics APIs only.
- No Screen Recording permission is required for wallpaper rendering.
- Display configuration changes are handled dynamically.

Known limitations:
- Advanced per-display performance tuning can be improved later.
- Menu-bar display controls are Stage 11.
- Login item is Stage 12.
- Settings refinement is Stage 13.
- Static wallpaper fallback is Stage 14.
