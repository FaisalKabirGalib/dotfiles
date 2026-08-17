# mpv — Media Player

GPU-accelerated video player tuned for high-resolution YouTube playback.

## Package Details

- **Type**: Media Player
- **Target**: `~/.config/mpv`
- **Dependencies**: mpv, yt-dlp, intel-media-driver (VA-API for Intel Gen8+)

## Install

```bash
stowup mpv
```

## Key Features

- VA-API hardware decode (`hwdec=vaapi`) for Intel Iris Xe
- GPU output via `vo=gpu-next`
- Up-to-8K YouTube streaming via yt-dlp, prefers VP9 so Tiger Lake's hardware
  decoder engages

## Notes

Used by the `yt` shell function (`zsh/.config/zsh/60-functions.zsh`), which
invokes mpv with `--hwdec=vaapi --vo=gpu-next` explicitly, so streaming works
even if this config is not stowed.

On a different GPU, change `hwdec`: `nvdec` for NVIDIA, `vulkan` as a portable
fallback, or `auto-safe` to let mpv decide. Verify what is actually in use with:

```bash
mpv --msg-level=vo=v,ffmpeg=v <file> 2>&1 | grep -i hwdec
```
