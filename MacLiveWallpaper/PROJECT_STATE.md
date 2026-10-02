# ## Current Stage

Stage 14 — Static Desktop Wallpaper Fallback

## Stage 14 Status

COMPLETED

## Stage 14 Implemented

- Added static wallpaper fallback using NSWorkspace.
- Extracts a representative frame from the selected video using AVAssetImageGenerator.
- Saves the extracted frame as a JPEG in the application's cache directory.
- Applies the JPEG as the macOS desktop wallpaper.
- Supports selecting the target NSScreen.
- Added logging for fallback creation and desktop wallpaper application.
- Added static fallback methods to the display wallpaper architecture.
- Added WallpaperRecoveryManager for future recovery integration.
- Removed temporary diagnostic "Test Static Wallpaper" button after successful testing.

## Stage 14 Testing

- Tested fallback generation successfully.
- Tested static wallpaper application successfully.
- Tested again after application relaunch successfully.
- No EXC_BAD_ACCESS crash.
- No crash when calling NSWorkspace.setDesktopImageURL.
- Verified on Built-in Retina Display.

## Important Implementation Decision

NSWorkspace desktop wallpaper options are currently passed as an empty dictionary:

[NSWorkspace.DesktopImageOptionKey: Any] = [:]

This avoids incorrect Swift-to-Objective-C bridging of NSImageScaling/Bool values that previously caused:

NSInvalidArgumentException:
-[__SwiftValue integerValue]

The macOS default desktop-image behavior is therefore currently used.

## Known Limitations

- Static fallback is not yet automatically triggered by system/recovery events.
- Static fallback is not yet automatically triggered when a live wallpaper becomes unavailable.
- Recovery behavior will be integrated in the system-integration/recovery stage.
- Lock Screen replacement is not implemented because macOS does not provide a supported public API for replacing the secure Lock Screen with a third-party live wallpaper.

## Not Yet Implemented

- Automatic recovery after login.
- Automatic recovery after display configuration changes.
- Automatic recovery after wake from sleep.
- Automatic recovery after wallpaper/window failure.
- Full system-state recovery coordination.
