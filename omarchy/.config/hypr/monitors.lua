-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

-- Straight 1x setup. eDP-1 is 1920x1080, so scale "auto" resolves to 2 and
-- renders a 960x540 logical desktop -- everything looks zoomed in. Keep both
-- of these at 1.
local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Fallback for any monitor not listed below.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Vertical alignment: external displays on top, laptop panel on the bottom.
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-1", mode = "preferred", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-2", mode = "preferred", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-3", mode = "preferred", position = "0x0", scale = 1 })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x1080", scale = 1 })

-- Pin workspaces 1-10 to the laptop panel and keep them alive.
for workspace = 1, 10 do
  hl.workspace_rule({
    workspace = tostring(workspace),
    monitor = "eDP-1",
    persistent = true,
    default = workspace == 1,
  })
end

-- Bind workspaces 11-20 to whichever external display is connected, and
-- re-bind them whenever displays come and go.
--
-- This replaces scripts/setup-external-workspaces.sh, which drove the same
-- logic through `hyprctl keyword`. That no longer works: under Omarchy 4's Lua
-- config provider hyprctl reports "keyword can't work with non-legacy parsers".
local function bind_external_workspaces()
  local external = "eDP-1"

  for _, monitor in ipairs(hl.get_monitors()) do
    if monitor.name ~= "eDP-1" then
      external = monitor.name
      break
    end
  end

  for workspace = 11, 20 do
    hl.workspace_rule({
      workspace = tostring(workspace),
      monitor = external,
      persistent = true,
    })
  end
end

bind_external_workspaces()

hl.on("monitor.added", bind_external_workspaces)
hl.on("monitor.removed", bind_external_workspaces)

-- HDMI port as a mirror of the laptop panel:
-- hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "1920x0", scale = 1, mirror = "eDP-1" })
