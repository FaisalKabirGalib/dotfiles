local colors = require("colors")
local settings = require("settings")

local front_app = sbar.add("item", "widgets.front_app", {
  position = "left",
  icon = { drawing = false },
  label = {
    font = { family = settings.font, style = "Bold", size = 13.0 },
    color = colors.text,
  },
  background = {
    color = colors.bg1,
    border_color = colors.surface2,
    border_width = 1,
    corner_radius = 6,
    height = 26,
  },
  padding_left = settings.group_paddings,
})

front_app:subscribe("front_app_switched", function(env)
  front_app:set({ label = { string = env.INFO } })
end)
