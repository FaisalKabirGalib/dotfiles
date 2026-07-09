-- Control-Center-style Bluetooth widget: icon reflects power state, click
-- for a popup listing paired devices (connect/disconnect each) plus a
-- power on/off toggle. Original design -- no direct reference
-- implementation existed to port from. Needs `blueutil`
-- (myansible tasks/sketchybar.yml).
local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local bt = sbar.add("item", "widgets.bluetooth", {
  position = "right",
  icon = { string = icons.bluetooth, color = colors.subtext0 },
  label = { drawing = false },
  update_freq = 10,
})

local power_toggle = sbar.add("item", "widgets.bluetooth.popup.toggle", {
  position = "popup." .. bt.name,
  icon = { string = "Bluetooth:", align = "left", width = 120 },
  label = { string = "...", align = "right", width = 100 },
})

local device_rows = {}

local function clear_device_rows()
  for _, row in ipairs(device_rows) do
    sbar.remove(row.name)
  end
  device_rows = {}
end

local function refresh_icon()
  sbar.exec("blueutil -p", function(power)
    local on = power and power:gsub("%s+$", "") == "1"
    bt:set({ icon = { color = on and colors.blue or colors.subtext0 } })
    power_toggle:set({ label = { string = on and "On" or "Off", color = on and colors.green or colors.red } })
  end)
end

local function refresh_devices()
  clear_device_rows()
  sbar.exec("blueutil --paired --format json", function(devices)
    for _, device in ipairs(devices or {}) do
      local display_name = device.name or device.address
      local safe_name = display_name:gsub("%s+", "_"):gsub("[^%w_]", "")
      local row = sbar.add("item", "widgets.bluetooth.device." .. safe_name, {
        position = "popup." .. bt.name,
        icon = {
          string = device.connected and icons.check or icons.cross,
          align = "left",
          width = 20,
          color = device.connected and colors.green or colors.subtext0,
        },
        label = { string = display_name, align = "left", width = 180 },
      })
      row:subscribe("mouse.clicked", function(_)
        local action = device.connected and "--disconnect" or "--connect"
        sbar.exec("blueutil " .. action .. " " .. device.address, function(_)
          refresh_devices()
        end)
      end)
      table.insert(device_rows, row)
    end
  end)
end

bt:subscribe("routine", refresh_icon)
bt:subscribe("forced", refresh_icon)

local function hide_popup()
  bt:set({ popup = { drawing = false } })
end

bt:subscribe("mouse.clicked", function(_)
  local should_draw = bt:query().popup.drawing == "off"
  if should_draw then
    refresh_icon()
    refresh_devices()
    bt:set({ popup = { drawing = true } })
  else
    hide_popup()
  end
end)

bt:subscribe("mouse.exited.global", hide_popup)

power_toggle:subscribe("mouse.clicked", function(_)
  sbar.exec("blueutil -p toggle", function(_)
    refresh_icon()
  end)
end)

sbar.add("item", "widgets.bluetooth.padding", { position = "right", width = settings.group_paddings })
