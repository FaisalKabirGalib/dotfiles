local colors = require("colors")

sbar.bar({
  height = 32,
  color = colors.bar.bg,
  border_color = colors.bar.border,
  shadow = false,
  sticky = true,
  padding_left = 8,
  padding_right = 8,
  topmost = "window",
})
