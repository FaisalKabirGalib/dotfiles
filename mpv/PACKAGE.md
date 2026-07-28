# mpv — Media Player

GPU-accelerated video player tuned for high-resolution YouTube playback on Apple Silicon.

## Package Details

- **Type**: Media Player
- **Target**: `~/.config/mpv`
- **Dependencies**: mpv, yt-dlp

## Install

```bash
stowup mpv
```

## Key Features

- VideoToolbox hardware decode (`hwdec=videotoolbox`)
- GPU output via `vo=gpu-next`
- Up-to-8K YouTube streaming via yt-dlp, prefers VP9 so the M2's hardware decoder engages
