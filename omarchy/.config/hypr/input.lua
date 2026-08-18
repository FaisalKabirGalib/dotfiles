-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
  input = {
    kb_layout = "us",

    -- Caps Lock acts as the compose key.
    -- Add ",grp:alts_toggle" to switch layouts with both Alt keys.
    kb_options = "compose:caps",

    repeat_rate = 40,
    repeat_delay = 600,
    numlock_by_default = true,

    touchpad = {
      scroll_factor = 0.4,
    },
  },
})

-- Ghostty needs a lower touchpad scroll speed than Omarchy's default.
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })
