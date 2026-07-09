-- Adapted from SbarLua's own example (example/items/calendar.lua), simpler
-- than falleco's version (no SF Symbols dependency needed).
local colors = require("colors")
local icons = require("icons")

local cal = sbar.add("item", "widgets.calendar", {
  position = "right",
  icon = {
    string = icons.calendar,
    color = colors.subtext0,
  },
  label = {
    width = 60,
    align = "right",
  },
  update_freq = 15,
})

local function update()
  cal:set({ icon = os.date("%a %d %b"), label = os.date("%H:%M") })
end

cal:subscribe("routine", update)
cal:subscribe("forced", update)
cal:subscribe("mouse.clicked", function(_)
  sbar.exec("open -a Calendar")
end)
