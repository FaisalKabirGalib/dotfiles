-- Slider + scroll/click adjust based on SbarLua's own example
-- (example/items/volume.lua). The output-device switch popup (via
-- SwitchAudioSource) is original -- neither falleco nor SbarLua's examples
-- have one to port from, so expect this part to need iteration.
local colors = require("colors")
local icons = require("icons")

local volume_slider = sbar.add("slider", "widgets.volume.slider", 100, {
  position = "right",
  updates = true,
  label = { drawing = false },
  icon = { drawing = false },
  slider = {
    highlight_color = colors.blue,
    width = 0,
    background = {
      height = 6,
      corner_radius = 3,
      color = colors.bg2,
    },
    knob = { string = "\u{2022}", drawing = false },
  },
})

local volume_icon = sbar.add("item", "widgets.volume.icon", {
  position = "right",
  icon = {
    string = icons.volume._100,
    width = 0,
    align = "left",
    color = colors.text,
  },
  label = { width = 25, align = "left" },
})

volume_slider:subscribe("mouse.clicked", function(env)
  sbar.exec("osascript -e 'set volume output volume " .. env["PERCENTAGE"] .. "'")
end)

volume_slider:subscribe("volume_change", function(env)
  local volume = tonumber(env.INFO)
  local icon = icons.volume._0
  if volume > 60 then
    icon = icons.volume._100
  elseif volume > 30 then
    icon = icons.volume._66
  elseif volume > 10 then
    icon = icons.volume._33
  elseif volume > 0 then
    icon = icons.volume._10
  end

  volume_icon:set({ label = icon })
  volume_slider:set({ slider = { percentage = volume } })
end)

local function animate_slider_width(width)
  sbar.animate("tanh", 30.0, function()
    volume_slider:set({ slider = { width = width } })
  end)
end

-- Output-device switch popup (SwitchAudioSource).
local device_bracket = sbar.add("bracket", "widgets.volume.bracket",
  { volume_icon.name, volume_slider.name }, {
    background = { color = colors.bg1, border_color = colors.rainbow[3], border_width = 1 },
    popup = { align = "center" },
  })

local device_rows = {}

local function clear_device_rows()
  for _, row in ipairs(device_rows) do
    sbar.remove(row.name)
  end
  device_rows = {}
end

local function hide_devices()
  device_bracket:set({ popup = { drawing = false } })
end

local function toggle_devices()
  local should_draw = device_bracket:query().popup.drawing == "off"
  if not should_draw then
    hide_devices()
    return
  end
  device_bracket:set({ popup = { drawing = true } })
  sbar.exec("SwitchAudioSource -a -t output", function(result)
    clear_device_rows()
    for device in result:gmatch("[^\r\n]+") do
      local safe_name = device:gsub("%s+", "_"):gsub("[^%w_]", "")
      local row = sbar.add("item", "widgets.volume.device." .. safe_name, {
        position = "popup." .. device_bracket.name,
        label = { string = device, align = "center" },
        width = 220,
      })
      row:subscribe("mouse.clicked", function(_)
        sbar.exec("SwitchAudioSource -s '" .. device .. "'")
        hide_devices()
      end)
      table.insert(device_rows, row)
    end
  end)
end

volume_icon:subscribe("mouse.clicked", function(env)
  if env.BUTTON == "right" then
    toggle_devices()
  else
    if tonumber(volume_slider:query().slider.width) > 0 then
      animate_slider_width(0)
    else
      animate_slider_width(100)
    end
  end
end)

-- Scroll on the icon to nudge volume without opening the slider.
volume_icon:subscribe("mouse.scrolled", function(env)
  local delta = tonumber(env.SCROLL_DELTA) or 0
  local step = delta > 0 and 5 or -5
  sbar.exec("osascript -e 'set volume output volume ((output volume of (get volume settings)) + (" .. step .. "))'")
end)

device_bracket:subscribe("mouse.exited.global", hide_devices)

sbar.add("item", "widgets.volume.padding", { position = "right", width = 5 })
