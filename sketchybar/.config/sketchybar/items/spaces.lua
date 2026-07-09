-- Workspace/window overview bar. Adapted from github.com/falleco/dotfiles
-- (sketchybar/items/spaces.lua), recolored into Catppuccin Mocha and changed
-- to a FIXED 10-slot loop (see items/aerospace.lua for why) instead of
-- upstream's dynamic get_workspaces().
local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local spaces = {}
local current_workspace = get_current_workspace()

local function build_label(apps)
  if apps == nil or #apps == 0 then
    return "" -- hide label on empty workspaces for a cleaner look
  end
  local icon_line = ""
  for _, app in ipairs(apps) do
    local app_name = app["app-name"]
    local icon = app_icons[app_name] or app_icons["default"]
    icon_line = icon_line .. " " .. icon
  end
  return icon_line
end

for i = 1, 10 do
  local selected = tostring(i) == current_workspace
  local accent = colors.rainbow[i]

  local space = sbar.add("item", "space." .. i, {
    icon = {
      string = tostring(i),
      font = { family = settings.font, style = "Bold" },
      color = selected and colors.base or colors.text,
      padding_left = settings.paddings + 2,
      padding_right = settings.paddings,
    },
    label = {
      font = settings.icons,
      color = selected and colors.base or colors.text,
      padding_left = settings.paddings,
      padding_right = settings.paddings + 4,
    },
    padding_left = 4,
    padding_right = 4,
    background = {
      color = selected and accent or colors.bg1,
      border_width = 1,
      border_color = accent,
      corner_radius = 6,
      height = 26,
    },
  })

  spaces[i] = space

  sbar.exec("aerospace list-windows --workspace " .. i .. " --json", function(apps)
    space:set({ label = build_label(apps) })
  end)

  space:subscribe("mouse.clicked", function(_)
    sbar.exec("aerospace workspace " .. i)
  end)

  -- Instant highlight swap on a workspace switch, fed by AeroSpace's
  -- exec-on-workspace-change hook (aerospace/.config/aerospace/aerospace.toml).
  space:subscribe("aerospace_workspace_change", function(env)
    local now_selected = env.FOCUSED_WORKSPACE == tostring(i)
    space:set({
      icon = { color = now_selected and colors.base or colors.text },
      label = { color = now_selected and colors.base or colors.text },
      background = { color = now_selected and accent or colors.bg1 },
    })
  end)
end

-- Catches windows opening/closing without a workspace switch. Deliberately
-- not adding AeroSpace's on-focus-changed hook for this (see PACKAGE.md) --
-- a single hidden poller repainting all 10 items in one pass is simpler and
-- matches the old bash version's exact two-trigger design (hook + 2s poll),
-- just relocated from one shell script into Lua item subscriptions.
local space_poller = sbar.add("item", "space.poller", {
  drawing = false,
  updates = true,
  update_freq = 2,
})

space_poller:subscribe("routine", function(_)
  for i = 1, 10 do
    sbar.exec("aerospace list-windows --workspace " .. i .. " --json", function(apps)
      spaces[i]:set({ label = build_label(apps) })
    end)
  end
end)
