local colors = require("colors")
local settings = require("settings")

sbar.add("item", "apple.logo", {
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
})

sbar.add("item", "apple.padding", { position = "left", width = settings.group_paddings })
