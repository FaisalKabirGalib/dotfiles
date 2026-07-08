local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Font configuration
config.font = wezterm.font("CaskaydiaMono Nerd Font", { weight = "Regular" })
config.font_size = 14

-- Window appearance
config.window_padding = {
	left = 3,
	right = 3,
	top = 3,
	bottom = 3,
}

config.window_background_opacity = 0.80
config.window_decorations = "RESIZE"
config.enable_tab_bar = false

-- Color scheme - Catppuccin Mocha
config.color_scheme = "Catppuccin Mocha"

-- Terminal settings
config.term = "xterm-256color"

-- tmux integration - use Option as Alt on macOS, Alt on Linux
if wezterm.target_triple == "x86_64-apple-darwin" or wezterm.target_triple == "aarch64-apple-darwin" then
	config.send_composed_key_when_left_alt_is_pressed = false
	config.send_composed_key_when_right_alt_is_pressed = false
else
	config.use_dead_keys = false
end

-- Key bindings that work well with tmux
config.keys = {
	-- Disable default CMD+T on macOS or Ctrl+Shift+T on Linux to avoid conflicts with tmux
	{
		key = "t",
		mods = wezterm.target_triple:find("apple") and "CMD" or "CTRL|SHIFT",
		action = wezterm.action.DisableDefaultAssignment,
	},
	-- Disable CMD+W on macOS or Ctrl+Shift+W on Linux
	{
		key = "w",
		mods = wezterm.target_triple:find("apple") and "CMD" or "CTRL|SHIFT",
		action = wezterm.action.DisableDefaultAssignment,
	},
}

-- Mouse bindings
config.mouse_bindings = {
	-- Right click paste
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = wezterm.action.PasteFrom("Clipboard"),
	},
}

-- Performance settings
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"

return config
