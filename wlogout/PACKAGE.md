# wlogout — Power Menu

[wlogout](https://github.com/ArtsyMacaw/wlogout) — a graphical logout/power menu for Wayland.

## Package Details

- **Type**: Power menu
- **Target**: `~/.config/wlogout`
- **Dependencies**: `wlogout` (AUR)

## Install

```bash
yay -S wlogout
stowup wlogout
```

## Key Features

- Six actions: Lock, Suspend, Logout, Hibernate, Reboot, Shutdown (vim-friendly keybinds `l/u/e/h/r/s`).
- Ethereal-themed: navy translucent buttons, indigo hover, frosted-glass blur via Hyprland `layerrule = blur on, match:namespace logout_dialog`.
- Bound to `SUPER + ESCAPE` (see `omarchy/.config/hypr/bindings.conf`) and the Waybar power button.
