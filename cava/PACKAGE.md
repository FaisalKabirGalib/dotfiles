# cava — Audio Visualizer

[cava](https://github.com/karlstav/cava) — a console-based audio spectrum visualizer.

## Package Details

- **Type**: Terminal audio visualizer
- **Target**: `~/.config/cava`
- **Dependencies**: `cava`

## Install

```bash
sudo pacman -S cava
stowup cava
```

## Key Features

- Ethereal-themed gradient (indigo `#7d82d9` at the base fading up to peach `#ffcead`).
- Reads desktop audio via the PipeWire PulseAudio server (`method = pulse`).
- Launch a floating visualizer window with `SUPER + ALT + V` (see `omarchy/.config/hypr/bindings.conf`); the float/size/center rule lives in `omarchy/.config/hypr/looknfeel.conf` matched on app-id `cava.visualizer`.
