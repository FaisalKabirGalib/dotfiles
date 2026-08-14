# @omarchy — Hyprland Wayland Compositor

Current Hyprland configuration (Wayland compositor), for Omarchy 4 ("Quattro").

## Package Details

- **Type**: Wayland Compositor
- **Target**: `~/.config/hypr`
- **Dependencies**: Hyprland, Omarchy 4+

## Install

```bash
stowup omarchy
```

## Structure

Hyprland is configured in **Lua**, not `.conf`. `hyprctl systeminfo` reports
`configProvider: lua`; Hyprland loads `hyprland.lua`, which pulls in Omarchy's
defaults and then each module below. **A `.conf` file dropped in here is
silently ignored.**

- `hyprland.lua` — entrypoint; loads Omarchy defaults, then requires the rest
- `monitors.lua` — display layout, 1x scaling, workspace-to-monitor pinning
- `input.lua` — keyboard/touchpad, per-app scroll speed
- `bindings.lua` — personal keybinding overrides
- `looknfeel.lua` — gaps, borders, blur, shadows, animations
- `autostart.lua` — startup applications

These three stay `.conf` — they are read by separate processes, not Hyprland:

- `hypridle.conf` — idle daemon (`hypridle`)
- `hyprlock.conf` — lock screen (`hyprlock`)
- `hyprsunset.conf` — night light (`hyprsunset`); apply with `omarchy restart hyprsunset`

Also shipped: `.config/xdg-terminals.list` — terminal preference order for
`xdg-terminal-exec` (Omarchy sets `$TERMINAL=xdg-terminal-exec`; first valid
entry wins). Currently **Ghostty** first, then kitty, then Alacritty.

## Editing

The Lua API is stubbed at `/usr/share/hypr/stubs/hl.meta.lua`; Omarchy's helpers
(`o.bind`, `o.window`, `o.launch_on_start`) live in
`/usr/share/omarchy/default/hypr/helpers.lua`. Read both before editing.

Two things that bite:

- `hyprctl keyword ...` no longer works ("keyword can't work with non-legacy
  parsers"). Anything that reconfigured Hyprland at runtime has to go through
  the Lua API instead (`hl.config`, `hl.animation`, `hl.workspace_rule`, `hl.on`).
- User files load *after* Omarchy's defaults, so rebinding a key that Omarchy
  already uses needs `hl.unbind("...")` first, or both bindings fire.

Validate every change with `hyprctl reload && hyprctl configerrors`.

## Key Features

- Modular Lua config
- Vim-style window navigation (`SUPER+CTRL+H/J/K/L`)
- `SUPER+<letter>` app launchers (the pre-Omarchy-4 layout, kept deliberately)
- Workspaces 1–10 pinned to the laptop panel, 11–20 to an external display
- Custom accent border gradient, blur, and animation curves

## Notes

The status bar, launcher and notifications are Omarchy 4's own Quickshell shell,
configured via `~/.config/omarchy/shell.json` (or `omarchy bar ...`). The
`waybar`, `walker` and swaync-based setup this package used to pair with is
retired.
