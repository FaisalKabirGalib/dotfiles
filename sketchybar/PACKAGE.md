# sketchybar — Workspace/Window Overview Bar (Lua/SbarLua)

Menu-bar overview of every AeroSpace workspace and its windows, plus a
handful of system widgets. AeroSpace has no built-in visual overview (no
equivalent to Hyprland's overview / GNOME Activities, and it doesn't use
real macOS Spaces so Mission Control doesn't show it either) — this fills
that gap. Written in Lua via [SbarLua](https://github.com/FelixKratz/SbarLua),
architecture adapted from [falleco/dotfiles](https://github.com/falleco/dotfiles),
recolored into Catppuccin Mocha. (An earlier bash-CLI version of this
package was replaced by this rewrite — see git history if you need it.)

## Package Details

- **Type**: Status/overview bar
- **Target**: `~/.config/sketchybar`
- **Dependencies**:
  - `sketchybar` (Homebrew formula `FelixKratz/formulae/sketchybar`)
  - `lua` (Homebrew formula — runs the `#!/usr/bin/env lua` sketchybarrc;
    SbarLua vendors its own Lua source and doesn't need this at build time)
  - `SbarLua` (built from source, installs to
    `~/.local/share/sketchybar_lua/sketchybar.so` — NOT a Homebrew package)
  - `sketchybar-app-font` (per-app icons in the workspace bar; installed to
    `~/Library/Fonts/`)
  - `switchaudio-osx` (Homebrew formula; powers the volume widget's
    output-device switch popup)
  - `aerospace` package (this repo) for the `aerospace` CLI
  - A C compiler (`clang`, ships with Xcode CLT) to build the two vendored
    event-provider helpers (CPU load, network throughput)
  - `JetBrainsMono Nerd Font` (already installed machine-wide via
    myansible's `casks.yml`)

  All of the above except the `aerospace`/dotfiles package itself are
  installed by `myansible`'s `tasks/sketchybar.yml` (tag `sketchybar`).

## Install

```bash
stowup sketchybar
cd ~/.config/sketchybar/helpers/event_providers && make   # or let sketchybarrc auto-build on next launch
brew services restart sketchybar   # picks up the new Lua sketchybarrc after stowing
```

## Architecture

- `sketchybarrc` sets up `package.path`/`package.cpath` for the config dir
  and `~/.local/share/sketchybar_lua`, self-heals by building SbarLua and
  the C event-provider helpers if missing (both no-ops once `myansible`'s
  `sketchybar` tag has provisioned the machine), then `require("init")`.
- `init.lua` → `bar.lua` (bar geometry) + `default.lua` (default item
  styling) + `items` (all bar content), wrapped in `sbar.begin_config()`/
  `sbar.end_config()` for a single atomic config push.
- `items/spaces.lua`: **fixed `for i = 1, 10 do ... end` loop**, not
  AeroSpace's dynamic `list-workspaces --all` (which only returns
  workspaces AeroSpace has already lazily created/visited) — matches this
  repo's aerospace config's `ctrl-1`..`ctrl-0` bindings, all 10 slots
  always visible.
- Per-app icons: `sketchybar-app-font` + `helpers/app_icons.lua`
  (AppName → font glyph-alias lookup table, vendored from
  falleco/dotfiles, with entries added for this machine's actual apps:
  Ghostty, Zen, WezTerm/`wezterm-gui`, OrbStack, Raycast).
- Refresh: AeroSpace's `exec-on-workspace-change` hook (already wired in
  `aerospace/.config/aerospace/aerospace.toml`, fires
  `aerospace_workspace_change` for instant feedback on a workspace switch)
  plus a hidden `update_freq=2` poll item in `spaces.lua` (catches windows
  opening/closing without a workspace switch) — same two-trigger design as
  the old bash version, just relocated into Lua item subscriptions.
  Deliberately did **not** add AeroSpace's `on-focus-changed` hook (see
  Follow-ups) — that hook exists upstream to drive a front-app display,
  which is out of scope here, so the poll is simpler and sufficient.
- Widgets (`items/calendar.lua`, `items/widgets/{volume,cpu,network}.lua`):
  clock/calendar, volume (scroll/click to adjust + right-click popup to
  switch output device via `SwitchAudioSource`), CPU load graph, network
  up/down speed — the latter two driven by compiled C helper binaries
  under `helpers/event_providers/{cpu_load,network_load}/bin/`, vendored
  from falleco/dotfiles and rebuilt automatically by `sketchybarrc` on
  every launch (idempotent, `make` no-ops if binaries are current).
  `network.lua` detects the active interface dynamically (`route get
  default`) rather than hardcoding `en0` like upstream does — this Mac
  Mini's actual default interface is `en1`.
- Explicitly **not** implemented: front-app display, media/now-playing,
  apple-menu/mode-toggle button, app-menu display, battery (Mac Mini has
  no battery).

## Follow-ups

- If per-app icon coverage feels incomplete, add entries to
  `helpers/app_icons.lua` (format: `["AppName"] = ":alias:"` — check valid
  alias names against
  [kvndrsslr/sketchybar-app-font's `mappings/` directory](https://github.com/kvndrsslr/sketchybar-app-font/tree/main/mappings)
  before adding one, an invalid alias silently renders as a fallback glyph).
- If window-open/close on the *current* workspace ever feels laggy
  (waiting up to 2s for the poll), consider adding AeroSpace's
  `on-focus-changed` hook (`sketchybar --trigger aerospace_focus_change
  FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE`) — deliberately skipped
  in this rewrite, see Architecture above.
- If you add workspaces past 10, extend both `items/spaces.lua`'s
  `for i = 1, 10` loop and the aerospace `ctrl-N` bindings together (same
  caveat the old bash version had).
- `sketchybar-app-font`'s pinned release version in
  `myansible/tasks/sketchybar.yml` may drift from upstream's latest tag
  over time — bump if icons look stale/missing for newer apps.
- The volume widget's device-switch popup is original design (no direct
  reference implementation existed in falleco or SbarLua's own examples)
  — if `SwitchAudioSource`'s output format ever changes, `items/widgets/
  volume.lua`'s `result:gmatch("[^\r\n]+")` parsing is the place to fix.
