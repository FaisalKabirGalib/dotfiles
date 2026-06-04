# swaync — Notification Center

[SwayNotificationCenter](https://github.com/ErikReider/SwayNotificationCenter) — a notification daemon with a slide-out control center, replacing Omarchy's default mako.

## Package Details

- **Type**: Notification daemon + control center
- **Target**: `~/.config/swaync`
- **Dependencies**: `swaync`

## Install

```bash
sudo pacman -S swaync
stowup swaync
```

## Key Features

- Slide-out control center with title bar, **Do Not Disturb** toggle, **MPRIS** media widget, and **volume** slider.
- Ethereal-themed (navy/peach/indigo), frosted-glass blur via Hyprland layer rules on `swaync-control-center` / `swaync-notification-window`.
- Toggle the panel with `SUPER + COMMA` (see `omarchy/.config/hypr/bindings.conf`).

## Notes / Reverting to mako

Omarchy ships **mako** as its default notifier and starts it from its read-only defaults. This package overrides that in `omarchy/.config/hypr/autostart.conf`:

```
exec-once = sh -c 'sleep 0.5; pkill -x mako; swaync'
```

To revert to mako: remove that line, run `pkill swaync; mako`, and `omarchy refresh waybar` is unaffected. mako stays installed as a fallback.
