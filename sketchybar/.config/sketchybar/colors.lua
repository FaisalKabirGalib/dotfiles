-- Catppuccin Mocha (https://catppuccin.com/palette), 0xAARRGGBB for sketchybar.
return {
  base = 0xff1e1e2e,
  mantle = 0xff181825,
  surface0 = 0xff313244,
  surface1 = 0xff45475a,
  surface2 = 0xff585b70,
  text = 0xffcdd6f4,
  subtext0 = 0xffa6adc8,
  overlay0 = 0xff6c7086,
  mauve = 0xffcba6f7,
  red = 0xfff38ba8,
  peach = 0xfffab387,
  yellow = 0xfff9e2af,
  green = 0xffa6e3a1,
  teal = 0xff94e2d5,
  sky = 0xff89dceb,
  blue = 0xff89b4fa,
  pink = 0xfff5c2e7,
  lavender = 0xffb4befe,
  transparent = 0x00000000,

  bar = { bg = 0xd01e1e2e, border = 0xff313244 },
  popup = { bg = 0xc01e1e2e, border = 0xff6c7086 },
  bg1 = 0xff313244,
  bg2 = 0xff45475a,

  -- Per-workspace accent rotation, 10 slots (replaces upstream's rainbow array).
  rainbow = { 0xffcba6f7, 0xff89b4fa, 0xffa6e3a1, 0xfff9e2af, 0xfffab387,
              0xfff38ba8, 0xff94e2d5, 0xff89dceb, 0xfff5c2e7, 0xffb4befe },

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then
      return color
    end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end
}
