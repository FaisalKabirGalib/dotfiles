local colors = require("colors")
local settings = require("settings")

local apple = sbar.add("item", "apple.logo", {
  position = "left",
  icon = {
    string = "\u{f179}", -- nf-fa-apple
    font = { family = settings.font, style = "Regular", size = 16.0 },
    color = colors.text,
    padding_left = settings.paddings + 4,
    padding_right = settings.paddings + 4,
  },
  label = { drawing = false },
  background = {
    color = colors.bg1,
    border_color = colors.surface2,
    border_width = 1,
    corner_radius = 6,
    height = 26,
  },
  padding_right = settings.group_paddings,
  popup = { align = "left" },
})

-- Apple-menu popup: recreate the native menu's system actions. Row build +
-- click-to-toggle / hide-on-exit mirror items/widgets/wifi.lua; popup bg/blur
-- styling is inherited from default.lua. Destructive rows (restart/shutdown/
-- logout) are guarded by a confirm dialog -- osascript exits non-zero on Cancel
-- so the `&&` short-circuits and the action never fires on a stray bar click.
local function confirm(question, verb, action)
  return "osascript -e 'display dialog \"" .. question .. "\" buttons {\"Cancel\",\"" ..
    verb .. "\"} default button \"Cancel\" with icon caution' >/dev/null 2>&1 && " .. action
end

local menu = {
  { icon = "\u{f129}", label = "About This Mac",   cmd = "open -b com.apple.SystemProfiler" },     -- nf-fa-info
  { icon = "\u{f013}", label = "System Settings…", cmd = "open -b com.apple.systempreferences" },  -- nf-fa-cog
  { icon = "\u{f290}", label = "App Store…",       cmd = "open -a 'App Store'" },                  -- nf-fa-shopping_bag
  { icon = "\u{f023}", label = "Lock Screen",      cmd = "pmset displaysleepnow" },                -- nf-fa-lock
  { icon = "\u{f186}", label = "Sleep",            cmd = "pmset sleepnow" },                       -- nf-fa-moon_o
  { icon = "\u{f021}", label = "Restart…",         cmd = confirm("Restart this Mac?", "Restart", "osascript -e 'tell app \"System Events\" to restart'") },      -- nf-fa-refresh
  { icon = "\u{f011}", label = "Shut Down…",       cmd = confirm("Shut Down this Mac?", "Shut Down", "osascript -e 'tell app \"System Events\" to shut down'") }, -- nf-fa-power_off
  { icon = "\u{f08b}", label = "Log Out…",         cmd = confirm("Log out now?", "Log Out", "osascript -e 'tell app \"System Events\" to log out'") },            -- nf-fa-sign_out
}

local function hide_popup()
  apple:set({ popup = { drawing = false } })
end

for i, entry in ipairs(menu) do
  local row = sbar.add("item", "apple.menu." .. i, {
    position = "popup.apple.logo",
    icon = { string = entry.icon, align = "left", width = 28, color = colors.subtext0 },
    label = { string = entry.label, align = "left", width = 170 },
  })
  row:subscribe("mouse.clicked", function(_)
    hide_popup()
    sbar.exec(entry.cmd)
  end)
end

apple:subscribe("mouse.clicked", function(_)
  local show = apple:query().popup.drawing == "off"
  apple:set({ popup = { drawing = show } })
end)

apple:subscribe("mouse.exited.global", hide_popup)

sbar.add("item", "apple.padding", { position = "left", width = settings.group_paddings })
