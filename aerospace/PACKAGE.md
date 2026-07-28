# aerospace — Tiling Window Manager

Tiling window manager for macOS (accessibility-API based, like yabai —
not a compositor). Mirrors the keybinding philosophy of this repo's

Hyprland config (`hyprland/`), adapted for macOS's real constraints.

## Package Details

- **Type**: Window Manager
- **Target**: `~/.config/aerospace`
- **Dependencies**: AeroSpace

## Install

```bash
stowup aerospace
```

**Important**: AeroSpace reads `~/.aerospace.toml` first, and only falls
back to `~/.config/aerospace/aerospace.toml` if that file doesn't exist.
If AeroSpace's own first-run onboarding already copied a default config to
`~/.aerospace.toml`, delete it — otherwise this package's config is
silently ignored.

## What's ported from Hyprland vs. not

Ported: workspace switching/moving, vim-motion focus navigation, close/
fullscreen/float toggles, app launchers, gaps, config reload, the
workspace-11/tmux and workspace-12/browser autostart.

Not ported (no AeroSpace/macOS equivalent — no compositor): borders,
rounding, blur, shadows, opacity, animations, Omarchy's dynamic theme
switching. Walker → Raycast/Spotlight. Waybar → native menu bar.
hypridle/hyprlock → native macOS sleep/lock. hyprsunset → Night Shift.

## Follow-ups

- `[workspace-to-monitor-force-assignment]` is left commented out in the
  config — the Mac Mini has no built-in display (unlike the laptop this
  was ported from), so fill this in only if/when running multiple
  external monitors.
- App-specific `[[on-window-detected]]` autostart rules need real macOS
  bundle IDs, which aren't guessed in the shipped config. Look one up via:
  ```bash
  osascript -e 'id of app "AppName"'
  # or
  mdls -name kMDItemCFBundleIdentifier /Applications/AppName.app
  ```
