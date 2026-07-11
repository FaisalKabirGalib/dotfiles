-- Control-Center-style Wi-Fi widget: SSID in the bar, click for a popup
-- with Wi-Fi info + an on/off toggle, plus a Bluetooth section (devices
-- + power toggle) so the click acts as a combined connectivity module.
local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local iface_handle = io.popen("networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}'")
local wifi_device = (iface_handle:read("*a"):gsub("%s+$", ""))
iface_handle:close()
if wifi_device == "" then
  wifi_device = "en0"
end

local wifi = sbar.add("item", "widgets.wifi", {
  position = "right",
  icon = { string = icons.wifi.connected, color = colors.text },
  label = { string = "...", width = 90, align = "left" },
  update_freq = 10,
})

local popup_ssid = sbar.add("item", "widgets.wifi.popup.ssid", {
  position = "popup." .. wifi.name,
  icon = { string = "SSID:", align = "left", width = 90 },
  label = { string = "...", align = "right", width = 140 },
})

local popup_ip = sbar.add("item", "widgets.wifi.popup.ip", {
  position = "popup." .. wifi.name,
  icon = { string = "IP:", align = "left", width = 90 },
  label = { string = "...", align = "right", width = 140 },
})

local popup_toggle = sbar.add("item", "widgets.wifi.popup.toggle", {
  position = "popup." .. wifi.name,
  icon = { string = "Wi-Fi:", align = "left", width = 90 },
  label = { string = "...", align = "right", width = 140 },
})

local bt_power = sbar.add("item", "widgets.wifi.bt.power", {
  position = "popup." .. wifi.name,
  icon = { string = "Bluetooth:", align = "left", width = 90 },
  label = { string = "...", align = "right", width = 140 },
})

local bt_device_rows = {}

local function clear_bt_device_rows()
  for _, row in ipairs(bt_device_rows) do
    sbar.remove(row.name)
  end
  bt_device_rows = {}
end

local function refresh_wifi()
  sbar.exec("ipconfig getifaddr " .. wifi_device, function(ip)
    local connected = ip ~= nil and ip:gsub("%s+", "") ~= ""
    wifi:set({
      icon = {
        string = connected and icons.wifi.connected or icons.wifi.disconnected,
        color = connected and colors.text or colors.red,
      },
    })
    popup_ip:set({ label = connected and ip or "not connected" })
  end)

  sbar.exec("ipconfig getsummary " .. wifi_device, function(summary)
    local ssid = summary and summary:match("SSID%s+:%s+([^\r\n]+)")
    if ssid and ssid ~= "" then
      wifi:set({ label = ssid })
      popup_ssid:set({ label = ssid })
    else
      sbar.exec("ipconfig getifaddr " .. wifi_device, function(ip)
        local connected = ip ~= nil and ip:gsub("%s+", "") ~= ""
        wifi:set({ label = connected and "Wi-Fi" or "off" })
        popup_ssid:set({ label = "not connected" })
      end)
    end
  end)

  sbar.exec("networksetup -getairportpower " .. wifi_device, function(result)
    local on = result and result:match("On") ~= nil
    popup_toggle:set({ label = { string = on and "On" or "Off", color = on and colors.green or colors.red } })
  end)
end

local function refresh_bt_icon()
  sbar.exec("blueutil -p", function(power)
    local on = power and power:gsub("%s+$", "") == "1"
    bt_power:set({ label = { string = on and "On" or "Off", color = on and colors.green or colors.red } })
  end)
end

local function refresh_bt_devices()
  clear_bt_device_rows()
  sbar.exec("blueutil --paired --format json", function(devices)
    for _, device in ipairs(devices or {}) do
      local display_name = device.name or device.address
      local safe_name = display_name:gsub("%s+", "_"):gsub("[^%w_]", "")
      local row = sbar.add("item", "widgets.wifi.bt.device." .. safe_name, {
        position = "popup." .. wifi.name,
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
          refresh_bt_devices()
        end)
      end)
      table.insert(bt_device_rows, row)
    end
  end)
end

local function refresh()
  refresh_wifi()
  refresh_bt_icon()
end

wifi:subscribe("routine", refresh)
wifi:subscribe("forced", refresh)
wifi:subscribe("system_woke", refresh)

local function hide_popup()
  wifi:set({ popup = { drawing = false } })
end

wifi:subscribe("mouse.clicked", function(_)
  local should_draw = wifi:query().popup.drawing == "off"
  if should_draw then
    refresh_wifi()
    refresh_bt_icon()
    refresh_bt_devices()
    wifi:set({ popup = { drawing = true } })
  else
    hide_popup()
  end
end)

wifi:subscribe("mouse.exited.global", hide_popup)

popup_toggle:subscribe("mouse.clicked", function(_)
  sbar.exec("networksetup -getairportpower " .. wifi_device, function(result)
    local on = result and result:match("On") ~= nil
    sbar.exec("networksetup -setairportpower " .. wifi_device .. " " .. (on and "off" or "on"), function(_)
      refresh_wifi()
    end)
  end)
end)

bt_power:subscribe("mouse.clicked", function(_)
  sbar.exec("blueutil -p", function(result)
    local on = result and result:gsub("%s+$", "") == "1"
    sbar.exec("blueutil -p " .. (on and "0" or "1"), function(_)
      refresh_bt_icon()
      refresh_bt_devices()
    end)
  end)
end)

sbar.add("item", "widgets.wifi.padding", { position = "right", width = settings.group_paddings })
