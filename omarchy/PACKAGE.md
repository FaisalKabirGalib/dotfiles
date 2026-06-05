# @omarchy — Hyprland Wayland Compositor

Current Hyprland configuration (Wayland compositor).

## Package Details

- **Type**: Wayland Compositor
- **Target**: `~/.config/hypr`
- **Dependencies**: Hyprland, Rofi, Waybar

## Install

```bash
stowup omarchy
```

## Structure

- `hyprland.conf` — Main config (includes defaults + custom)
- `defaults.conf` — Defaults
- `custom.conf` — Custom keybindings
- `.config/xdg-terminals.list` — Default terminal preference order for `xdg-terminal-exec` (Omarchy sets `$TERMINAL=xdg-terminal-exec`; first valid entry wins). Currently **Ghostty** first, then kitty, then Alacritty.

## Key Features

- Modular config (includes)
- Vim-style window navigation
- Application launcher (Rofi)
- Custom keybindings for window management