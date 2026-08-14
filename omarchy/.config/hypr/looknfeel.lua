-- Change the default Omarchy look'n'feel.

local accent = "rgba(7d82d9ff)"
local peach = "rgba(ffceadff)"
local dim_border = "rgba(3c486d66)"

local active_border_color = { colors = { peach, accent }, angle = 45 }
local inactive_border_color = dim_border

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 2,

    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },

    resize_on_border = true,
  },

  -- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
  decoration = {
    rounding = 10,

    active_opacity = 1.0,
    inactive_opacity = 0.92,
    fullscreen_opacity = 1.0,

    dim_inactive = true,
    dim_strength = 0.08,

    blur = {
      enabled = true,
      size = 6,
      passes = 3,
      new_optimizations = true,
      ignore_opacity = true,
      xray = false,
      noise = 0.015,
      contrast = 1.0,
      brightness = 0.9,
      vibrancy = 0.18,
      vibrancy_darkness = 0.05,
    },

    shadow = {
      enabled = true,
      range = 18,
      render_power = 3,
      color = "rgba(060b1ecc)",
      color_inactive = "rgba(060b1e88)",
    },
  },

  animations = {
    enabled = true,
  },
})

-- Match the window borders on grouped windows.
hl.config({
  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },
})

-- Custom animation curves.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeOutExpo", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("snappy", { type = "bezier", points = { { 0.4, 0 }, { 0.2, 1 } } })
hl.curve("smoothOut", { type = "bezier", points = { { 0.36, 0 }, { 0.66, -0.56 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "overshot", style = "popin 60%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "overshot", style = "popin 60%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "smoothOut", style = "popin 70%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "snappy" })
hl.animation({ leaf = "border", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "snappy" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 4, bezier = "snappy" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 3, bezier = "smoothOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "overshot", style = "slidefade 15%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "overshot", style = "slidefadevert 15%" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "snappy", style = "slide" })

-- Blur the surfaces that sit on top of the desktop.
-- The old swaync/walker rules are gone: Omarchy 4 draws the bar, launcher and
-- notifications itself (namespaces "omarchy-bar" / "omarchy-background") and
-- styles them through the active theme.
hl.layer_rule({ match = { namespace = "logout_dialog" }, blur = true })

-- Audio visualizer popup.
o.window("^(cava\\.visualizer)$", { float = true, size = "900 360", center = true })
