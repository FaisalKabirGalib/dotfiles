# Omarchy 4 ("Quattro") — what changed and what to use

Notes taken on 2026-08-15, the day this machine upgraded to **4.0.0.alpha**.
Everything below was verified against the running system (`omarchy commands`,
`omarchy plugin list`, and the Lua sources under `/usr/share/omarchy/`), not
recalled from documentation.

Baseline at time of writing: Omarchy 4.0.0.alpha, channel `stable`,
Hyprland 0.56.2, 431 commands across ~75 groups, 37 shell plugins (31 enabled),
446 migrations applied.

---

## 1. One process now draws the desktop

The single biggest change. **waybar, walker, swaync and mako are gone**,
replaced by one Quickshell process (`omarchy-launch-shell`) that draws the bar,
launcher, notifications, on-screen display, lock screen, clipboard manager and
emoji picker.

Everything it draws is a **plugin**. Config lives in
`~/.config/omarchy/shell.json` and **hot-reloads on save** — no restart needed.

### Plugins currently disabled here

| Plugin | Adds |
|---|---|
| `omarchy.active-window` | Current window title in the bar |
| `omarchy.media` | Now-playing with transport controls |
| `omarchy.microphone` | Mic mute state and level |
| `omarchy.tailscale` | Tailscale connection state |
| `omarchy.dropbox` | Dropbox sync status |
| `omarchy.spacer` | Layout spacing control |

```bash
omarchy plugin list                      # all plugins + state
omarchy plugin enable omarchy.media
omarchy menu plugin enable               # pick from a menu
```

### Panels — full-screen overlays, a new category

`speedtest`, `wifiqr` (shows the Wi-Fi network as a scannable QR code),
`disk-speedtest`, `dev-gallery`, and the OSD. All enabled.

### Moving the bar

```bash
omarchy bar position left        # vertical — buys back vertical pixels on 1080p
omarchy bar position top         # revert
omarchy bar transparent toggle
omarchy bar text color
```

The clock widget in `shell.json` already carries a `verticalFormat`
(`"HH\n—\nmm"`) for exactly this.

### Customising a built-in widget

Never edit the packaged copy under `/usr/share/omarchy/` — it is overwritten on
update. Clone it instead:

```bash
omarchy plugin clone omarchy.clock       # becomes galib.clock in ~/.config
```

The bar is switched over to the clone automatically.

---

## 2. Universal copy and paste

The cleverest small feature in the release.

| Keys | Does |
|---|---|
| `SUPER+C` / `SUPER+V` / `SUPER+X` | Copy / paste / cut in **every** application |
| `SUPER+CTRL+V` | Clipboard history manager |

Omarchy checks whether the focused window is a terminal first (via the
`terminal` window tag) and silently sends `CTRL+Insert` / `SHIFT+Insert` there
instead. One pair of keys that works in both GUI and terminal.

> **Note for this machine:** `bindings.lua` overrides `SUPER+C` (Calendar) and
> `SUPER+X` (X), so universal copy and cut are unbound while paste still works.
> Moving those two web apps onto `SUPER+ALT` would restore the clipboard.

---

## 3. What the keyboard reaches

### Menus

| Keys | Opens |
|---|---|
| `SUPER+SPACE` | Root Omarchy menu — everything hangs off this |
| `SUPER+ALT+SPACE` | Application launcher |
| `SUPER+ESC` | System menu (lock, suspend, restart, shutdown) |
| `SUPER+CTRL+O` | Toggle menu — every on/off switch in one place |
| `SUPER+CTRL+C` | Capture menu |
| `SUPER+CTRL+SPACE` | Background switcher |
| `SUPER+SHIFT+CTRL+SPACE` | Theme menu (20 themes ship built in) |

### Instant toggles

| Keys | Does |
|---|---|
| `SUPER+BACKSPACE` | Toggle transparency on the focused window |
| `SUPER+SHIFT+BACKSPACE` | Toggle gaps off — full-bleed for the current window |
| `SUPER+CTRL+BACKSPACE` | Square up a lone window on a wide screen |
| `SUPER+CTRL+Z` | Zoom the compositor in (`SUPER+CTRL+ALT+Z` resets) |
| `SUPER+CTRL+DELETE` | Toggle the laptop display off — useful when docked |
| `SUPER+L` | Switch this workspace between tiling and **scrolling** layout |

**Scrolling layout** is niri-style: columns scroll horizontally instead of
subdividing. It is **per workspace**, and the choice is saved and restored
across restarts (`omarchy hyprland workspace layout toggle`).

### Utilities

| Keys | Does |
|---|---|
| `SUPER+CTRL+R` | Set a reminder — also `omarchy reminder 15 "Stand up"` |
| `SUPER+CTRL+Q` | Calculator |
| `SUPER+CTRL+S` | Share a file |
| `SUPER+CTRL+.` | Transcode media |
| `SUPER+SHIFT+ALT+,` | Notification history |

---

## 4. The capture suite

| Trigger | Does |
|---|---|
| `PRINT` | Screenshot — region / window / smart / fullscreen, over a frozen screen |
| `ALT+PRINT` | Screen recording — desktop audio, mic, and a resizable **webcam overlay** |
| `SUPER+CTRL+PRINT` | **OCR** — drag a region, get its text on the clipboard |
| `SUPER+PRINT` | Colour picker |
| `omarchy capture qr` | Decode a QR code anywhere on screen |
| `tensaku` | Screenshot annotation (arrows, boxes, callouts) — installed |

Webcam overlay resizes live during recording with `SUPER+ALT+[` / `SUPER+ALT+]`.

---

## 5. Built for running coding agents

An unusual bet for a distro, and the most relevant part for this machine.

- **`omarchy.agents` bar widget** (enabled) tracks usage and rate-limit windows
  for Claude Code, Codex and Fireworks.
  Query directly: `omarchy agent usage claude --limits-only`
- **`herdr`** (installed) — a terminal workspace manager built specifically for
  AI coding agents; think tmux, but the unit of work is an agent session.
  Supports remote sessions over SSH. `SUPER+CTRL+RETURN` attaches.
- **Crash diagnosis** — `omarchy agent crash <pid>` hands a core dump straight
  to the default agent. Desktop crash notifications are wired to it.

---

## 6. Bundled applications

| App | What it is | Reach it with |
|---|---|---|
| `herdr` | Terminal workspace manager for coding agents | `SUPER+CTRL+RETURN` |
| `tensaku` | Screenshot annotation | via capture menu |
| `omawrite` | Dead-simple Markdown writing app (Qt Quick) | `SUPER+SHIFT+W` |
| `cliamp` | Retro terminal music player | `SUPER+SHIFT+ALT+M` |
| `voxtype` | Local AI voice dictation — **not installed** | `omarchy voxtype install` |

---

## 7. Automation and update channels

### Hooks

Drop a script into a `.d` directory under `~/.config/omarchy/hooks/` and it runs
on that event. Six types exist:

`theme-set` · `post-update` · `post-boot` · `battery-low` · `font-set` · `pre-refresh-pacman`

```bash
omarchy hook install theme-set ~/.local/bin/my-script
```

A `theme-set` hook is the clean way to push a colour change out to apps Omarchy
does not manage — Neovim or tmux, for instance.

### Channels

Currently on **stable**. `omarchy channel set rc` moves to release candidates,
`edge` to nightly. Given that the 4.0 alpha shipped a config-format migration
that silently orphaned this repo's dotfiles, stable is the right place to stay.

---

## 8. Worth doing on this machine

Roughly in order of payoff:

1. **Restore a direct lock key.** The vim focus bindings in `bindings.lua` took
   `SUPER+CTRL+L` (Lock system), `SUPER+CTRL+H` (Hardware menu) and
   `SUPER+CTRL+K` (Herdr keybindings). Lock is still reachable via `SUPER+ESC`.
2. **Reclaim universal copy/cut** by moving Calendar and X off `SUPER+C` / `SUPER+X`.
3. **Try `herdr`** — this repo maintains configs for Claude Code, Gemini, pi and
   opencode; herdr is built for exactly that workload.
4. **Install voxtype** if dictation appeals — runs a local model, nothing leaves
   the machine.
5. **Try the vertical bar** — `omarchy bar position left`.
6. **Enable `omarchy.media`** for transport controls in the bar.
### Unrelated loose end

Every file in `~/.config/hypr/shaders/` is a dangling symlink into
`/usr/share/aether/shaders/` — the `aether` package is not installed. These were
never part of this repo. Either install `aether` or delete the directory.

---

## 9. Finding the rest

431 commands is more than any document should list. The CLI is self-documenting:

```bash
omarchy commands                 # every documented command with a summary
omarchy <group> --help           # drill into one group: theme, capture, bar
omarchy commands --json          # machine-readable, for scripting
omarchy menu keybindings         # searchable list of every live binding
cat $(which omarchy-theme-set)   # read any command's source — it is all shell
```

See also `PACKAGE.md` in this directory for how the Hyprland Lua config is
structured, and the repo `CLAUDE.md` for the constraints that come with it.
