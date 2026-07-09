-- Control-Center-style Wi-Fi widget: SSID in the bar, click for a popup
-- with IP + an on/off toggle (networksetup -setairportpower). Original
-- design (no direct reference implementation) -- separate from
-- items/widgets/network.lua, which is generic up/down throughput on
-- whatever the default-route interface is.
--
-- The Wi-Fi hardware port is detected dynamically via
-- `networksetup -listallhardwareports`, not hardcoded -- same lesson as
-- network.lua's en0/en1 fix: verify the real device name, don't assume it.
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

local function refresh()
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

  -- `networksetup -getairportnetwork` needs Location Services permission
  -- to actually return the SSID (macOS restriction since Big Sur); a
  -- background brew-services process typically doesn't have it, so this
  -- often reports "not associated" even while genuinely connected. Fall
  -- back to a generic label instead of a misleading "off" when that
  -- happens -- the icon's connected/disconnected color (above, driven by
  -- whether we actually have an IP) is the more reliable signal.
  sbar.exec("networksetup -getairportnetwork " .. wifi_device, function(result)
    local ssid = result and result:match(": (.+)")
    if ssid then
      wifi:set({ label = ssid })
      popup_ssid:set({ label = ssid })
    else
      sbar.exec("ipconfig getifaddr " .. wifi_device, function(ip)
        local connected = ip ~= nil and ip:gsub("%s+", "") ~= ""
        wifi:set({ label = connected and "Wi-Fi" or "off" })
        popup_ssid:set({ label = "unavailable (Location Services)" })
      end)
    end
  end)

  sbar.exec("networksetup -getairportpower " .. wifi_device, function(result)
    local on = result and result:match("On") ~= nil
    popup_toggle:set({ label = { string = on and "On" or "Off", color = on and colors.green or colors.red } })
  end)
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
    refresh()
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
      refresh()
    end)
  end)
end)

sbar.add("item", "widgets.wifi.padding", { position = "right", width = settings.group_paddings })
