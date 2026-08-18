-- Personal keybinding overrides.
--
-- See current bindings and descriptions:
--   omarchy menu keybindings --print
--
-- Omarchy 4 moved most app launchers onto SUPER+SHIFT. These bindings keep the
-- older SUPER+<letter> layout, so anything that collides with a default is
-- unbound first -- the previous meaning is noted on each unbind.

-- ---------------------------------------------------------------------------
-- Terminals
-- ---------------------------------------------------------------------------

hl.unbind("SUPER + RETURN") -- was: Terminal
o.bind("SUPER + RETURN", "Terminal", { launch = '$TERMINAL --working-directory="$(omarchy-cmd-terminal-cwd)"' })

hl.unbind("SUPER + ALT + RETURN") -- was: Tmux
o.bind("SUPER + ALT + RETURN", "Tmux", 'uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" tmux new')

-- ---------------------------------------------------------------------------
-- Applications
-- ---------------------------------------------------------------------------

o.bind("SUPER + B", "Browser", "omarchy-launch-browser")

hl.unbind("SUPER + SHIFT + B") -- was: Browser
o.bind("SUPER + SHIFT + B", "Browser (private)", "omarchy-launch-browser --private")

o.bind("SUPER + N", "Editor", "omarchy-launch-editor")

hl.unbind("SUPER + T") -- was: Toggle window floating/tiling
o.bind("SUPER + T", "Activity", { tui = "btop" })

o.bind("SUPER + D", "Docker", { tui = "lazydocker" })

hl.unbind("SUPER + G") -- was: Toggle window grouping
o.bind("SUPER + G", "Signal", { launch = "signal-desktop", focus = "signal" })

hl.unbind("SUPER + O") -- was: Pop window out (float & pin)
o.bind("SUPER + O", "Obsidian", { launch = "obsidian -disable-gpu --enable-wayland-ime", focus = "obsidian" })

o.bind("SUPER + E", "Files", { launch = "nemo" })

-- ---------------------------------------------------------------------------
-- Web apps
-- ---------------------------------------------------------------------------

o.bind("SUPER + A", "ChatGPT", { webapp = "https://chatgpt.com" })

hl.unbind("SUPER + SHIFT + A") -- was: ChatGPT
o.bind("SUPER + SHIFT + A", "Grok", { webapp = "https://grok.com" })

hl.unbind("SUPER + C") -- was: Universal copy
o.bind("SUPER + C", "Calendar", { webapp = "https://app.hey.com/calendar/weeks/" })

o.bind("SUPER + Y", "YouTube", { webapp = "https://youtube.com/", focus = true })

hl.unbind("SUPER + SHIFT + G") -- was: Signal
o.bind("SUPER + SHIFT + G", "WhatsApp", { webapp = "https://web.whatsapp.com/", focus = true })

hl.unbind("SUPER + ALT + G") -- was: Move active window out of group
o.bind("SUPER + ALT + G", "Google Messages", { webapp = "https://messages.google.com/web/conversations", focus = true })

hl.unbind("SUPER + X") -- was: Universal cut
o.bind("SUPER + X", "X", { webapp = "https://x.com/" })

hl.unbind("SUPER + SHIFT + X") -- was: X
o.bind("SUPER + SHIFT + X", "X Post", { webapp = "https://x.com/compose/post" })

-- ---------------------------------------------------------------------------
-- Window management
-- ---------------------------------------------------------------------------

o.bind("SUPER + M", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

hl.unbind("SUPER + F") -- was: Full screen
o.bind("SUPER + F", "Toggle window floating", hl.dsp.window.float({ action = "toggle" }))

o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
o.bind("SUPER + SHIFT + ALT + Q", "Pick and kill a window", "hyprctl kill")

-- Vim-style focus movement.
hl.unbind("SUPER + CTRL + H") -- was: Hardware menu
hl.unbind("SUPER + CTRL + K") -- was: Herdr keybindings
hl.unbind("SUPER + CTRL + L") -- was: Lock system
o.bind("SUPER + CTRL + H", "Focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + CTRL + J", "Focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + CTRL + K", "Focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + CTRL + L", "Focus right", hl.dsp.focus({ direction = "r" }))

-- ---------------------------------------------------------------------------
-- Workspaces
-- ---------------------------------------------------------------------------
--
-- SUPER+1..0 (switch) and SUPER+SHIFT+1..0 (move window) already map to
-- workspaces 1-10 in Omarchy's defaults, so they are not redefined here.
-- These add workspaces 11-20 on CTRL, for the external display.

for workspace = 11, 20 do
  local key = "code:" .. tostring(workspace - 1) -- 11 -> code:10 (the "1" key)

  o.bind("CTRL + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind(
    "CTRL + SHIFT + " .. key,
    "Move window to workspace " .. workspace,
    hl.dsp.window.move({ workspace = tostring(workspace) })
  )
end

-- ---------------------------------------------------------------------------
-- Utilities
-- ---------------------------------------------------------------------------

o.bind("SUPER + ALT + V", "Audio visualizer", { launch = "ghostty --class=cava.visualizer -e cava" })

-- Toggle the animated rotating gradient border (off by default, for battery).
--
-- This used to live in ~/.local/bin/toggle-border-anim, which drove it through
-- `hyprctl keyword` -- unavailable under the Lua config provider. Doing it in
-- process avoids shelling out entirely.
local border_anim_on = false

hl.bind("SUPER + ALT + B", function()
  border_anim_on = not border_anim_on

  if border_anim_on then
    hl.animation({ leaf = "borderangle", enabled = true, speed = 50, bezier = "linear", style = "loop" })
  else
    hl.animation({ leaf = "borderangle", enabled = false })
  end

  hl.exec_cmd(
    "notify-send -u low -t 1500 'Border animation' '" .. (border_anim_on and "On" or "Off") .. "'"
  )
end, { description = "Toggle border animation" })

-- Omarchy's defaults own the system menu and notification shortcuts.
