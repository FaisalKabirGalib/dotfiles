-- Trimmed/adapted from github.com/falleco/dotfiles
-- (sketchybar/items/widgets/wifi.lua) -- upload/download speed only, the
-- SSID/hostname/IP/router popup was out of scope for this rewrite.
--
-- IMPORTANT deviation from upstream: falleco hardcodes the interface name
-- "en0". Verified live on this Mac Mini that its actual default-route
-- interface is "en1", not "en0" -- so the interface is detected dynamically
-- here instead of hardcoded.
local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local config_dir = os.getenv("HOME") .. "/.config/sketchybar"

local current_iface = nil

local function setup_network_load()
  local iface_handle = io.popen("/sbin/route -n get default 2>/dev/null | awk '/interface:/{print $2}'")
  local new_iface = (iface_handle:read("*a"):gsub("%s+$", ""))
  iface_handle:close()
  if new_iface == "" then
    new_iface = "en0"
  end

  if new_iface ~= current_iface then
    current_iface = new_iface
    sbar.exec("killall network_load >/dev/null 2>&1; " .. config_dir ..
      "/helpers/event_providers/network_load/bin/network_load " .. current_iface .. " network_update 2.0")
  else
    sbar.exec("pgrep -lf 'network_load " .. current_iface .. "'", function(result)
      if result == "" or result == nil then
        sbar.exec("killall network_load >/dev/null 2>&1; " .. config_dir ..
          "/helpers/event_providers/network_load/bin/network_load " .. current_iface .. " network_update 2.0")
      end
    end)
  end
end

setup_network_load()

local net_up = sbar.add("item", "widgets.network.up", {
  position = "right",
  padding_left = settings.paddings,
  padding_right = 0,
  icon = { string = icons.wifi.upload, padding_right = settings.paddings },
  label = { color = colors.red, string = "??? Bps", width = 58, align = "right" },
  y_offset = 5,
})

local net_down = sbar.add("item", "widgets.network.down", {
  position = "right",
  padding_left = 0,
  padding_right = settings.paddings,
  icon = { string = icons.wifi.download, padding_right = settings.paddings },
  label = { color = colors.blue, string = "??? Bps", width = 58, align = "right" },
  y_offset = -5,
})

sbar.add("bracket", "widgets.network.bracket", { net_up.name, net_down.name }, {
  background = { color = colors.bg1, border_color = colors.rainbow[8], border_width = 1 },
})

sbar.add("item", "widgets.network.padding", { position = "right", width = settings.group_paddings })

net_up:subscribe("network_update", function(env)
  local up_color = (env.upload == "000 Bps") and colors.subtext0 or colors.red
  local down_color = (env.download == "000 Bps") and colors.subtext0 or colors.blue
  net_up:set({ icon = { color = up_color }, label = { string = env.upload, color = up_color } })
  net_down:set({ icon = { color = down_color }, label = { string = env.download, color = down_color } })
end)

net_up:subscribe("wifi_change", setup_network_load)
net_up:subscribe("system_woke", setup_network_load)
