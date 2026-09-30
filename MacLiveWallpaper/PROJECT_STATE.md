# ## Stage 6 — Wallpaper Scaling

Implemented:
- VideoScalingMode
- Fill mode
- Fit mode
- Center mode
- AVPlayerLayer aspect-ratio-preserving presentation
- Manual centered video presentation
- Scaling selection in main UI
- Wallpaper engine accepts selected scaling mode

Scaling behavior:
- Fill = resizeAspectFill
- Fit = resizeAspect
- Center = manually centered presentation

Important:
- Original video file is never modified.
- No conversion or re-encoding is performed.
- Fill may crop video edges.
- Fit may leave unused/black areas.
- Center does not upscale a smaller source video.

Not implemented yet:
- Persistent scaling preference
- Settings window integration
- Seamless AVPlayerLooper
- Battery optimization
- Per-display scaling preferences
