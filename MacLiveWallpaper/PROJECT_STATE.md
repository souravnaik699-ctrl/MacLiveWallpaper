# ## Stage 9 — Battery & Performance Optimization

Implemented:
- Performance modes
- Quality mode
- Balanced mode
- Battery Saver mode
- Low Power Mode monitoring
- Thermal state monitoring
- Battery percentage monitoring
- Battery threshold
- System sleep handling
- Display sleep handling
- System wake handling
- Display wake handling
- Automatic playback pause/resume
- Manual pause protection
- Video performance analysis
- Resolution/frame-rate performance warnings
- Codec identification
- Playability/decodability checking

Performance architecture:

VideoPlayerController
        ↓
WallpaperPerformanceController
        ↓
SystemPowerMonitor
        ↓
Low Power Mode
Battery Level
Thermal State
Sleep/Wake
Occlusion

Important decisions:
- Original video files are never modified.
- No video re-encoding.
- No artificial resolution reduction.
- No private macOS APIs.
- Performance optimization controls playback rather than degrading source quality.
- Automatic pause never overrides a user's intentional manual pause.
- Actual battery/CPU savings are not guaranteed because they depend on system workload, video characteristics, displays, and hardware.

Known limitations:
- Advanced multi-display optimization is Stage 10.
- Menu-bar controls are Stage 11.
- Login item is Stage 12.
- Settings refinement is Stage 13.
- Static wallpaper fallback is Stage 14.
