-- System-at-a-glance module: RAM / Disk / GPU as icon + live mini-graph inside
-- one bracketed module with thin dividers between the three. Same graph +
-- threshold-color pattern as cpu.lua; shell-polled (no C event provider) since
-- these sources are cheap and change slowly.
-- ponytail: 5s shell poll of memory_pressure/df/ioreg. Upgrade path if it ever
-- feels stale: a C event provider like helpers/event_providers/cpu_load.
local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local function load_color(v)
  if v < 30 then
    return colors.blue
  elseif v < 60 then
    return colors.yellow
  elseif v < 80 then
    return colors.peach
  else
    return colors.red
  end
end

local graph_opts = {
  position = "right",
  background = { height = 22, color = { alpha = 0 }, border_color = { alpha = 0 }, drawing = true },
}

local function add_graph(name, icon, title)
  local opts = {}
  for k, v in pairs(graph_opts) do opts[k] = v end
  opts.graph = { color = colors.blue }
  opts.icon = { string = icon, padding_left = settings.paddings, padding_right = settings.paddings }
  -- Label overlays the graph area (align left, no reserved width) so the widget
  -- stays compact, cpu.lua-style. Text names which stat it is.
  opts.label = { string = title .. " ??%", align = "left", padding_left = settings.paddings }
  return sbar.add("graph", name, 40, opts)
end

local function add_sep(name)
  return sbar.add("item", name, {
    position = "right",
    icon = { string = "\u{2502}", color = colors.surface2 },
    label = { drawing = false },
  })
end

local ram = add_graph("widgets.sys.ram", icons.ram, "ram")
local sep1 = add_sep("widgets.sys.sep1")
local disk = add_graph("widgets.sys.disk", icons.disk, "disk")
local sep2 = add_sep("widgets.sys.sep2")
local gpu = add_graph("widgets.sys.gpu", icons.gpu, "gpu")

-- One exec per tick emits "ram disk gpu" as whole-number percentages.
local stats_cmd = [[
ram=$(memory_pressure 2>/dev/null | awk '/free percentage/{gsub(/%/,"",$NF); print 100-$NF}')
disk=$(df / | awk 'NR==2{gsub(/%/,"",$5); print $5}')
gpu=$(ioreg -r -d 1 -w 0 -c IOAccelerator 2>/dev/null | grep -o '"Device Utilization %"=[0-9]*' | head -1 | grep -o '[0-9]*$')
printf '%s %s %s' "${ram:-0}" "${disk:-0}" "${gpu:-0}"
]]

local function push_stat(graph, title, v)
  graph:push({ v / 100. })
  graph:set({ graph = { color = load_color(v) }, label = title .. " " .. v .. "%" })
end

local function update_all()
  sbar.exec(stats_cmd, function(out)
    local r, d, g = tostring(out):match("(%d+)%s+(%d+)%s+(%d+)")
    if not r then return end
    push_stat(ram, "ram", tonumber(r))
    push_stat(disk, "disk", tonumber(d))
    push_stat(gpu, "gpu", tonumber(g))
  end)
end

ram:set({ update_freq = 5 })
ram:subscribe("routine", update_all)
ram:subscribe("forced", update_all)
ram:subscribe("system_woke", update_all)

for _, item in ipairs({ ram, disk, gpu }) do
  item:subscribe("mouse.clicked", function(_)
    sbar.exec("open -a 'Activity Monitor'")
  end)
end

sbar.add("bracket", "widgets.sys.bracket", { ram.name, sep1.name, disk.name, sep2.name, gpu.name }, {
  background = { color = colors.bg1, border_color = colors.rainbow[6], border_width = 1 },
})

sbar.add("item", "widgets.sys.padding", { position = "right", width = settings.group_paddings })
