-- System-at-a-glance: RAM / Disk / GPU, each its own compact chip = icon + live
-- mini-graph with the percent label drawn ON TOP of the graph (negative label
-- padding) to stay narrow. Each chip's bracket border color reflects stress
-- level (blue->yellow->peach->red), same thresholds as cpu.lua. Shell-polled.
-- ponytail: 5s shell poll of memory_pressure/df/ioreg. Upgrade path if it ever
-- feels stale: a C event provider like helpers/event_providers/cpu_load.
local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local GRAPH_W = 48

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

local function add_stat(id, icon, title)
  local graph = sbar.add("graph", "widgets.sys." .. id, GRAPH_W, {
    position = "right",
    background = { height = 22, color = { alpha = 0 }, border_color = { alpha = 0 }, drawing = true },
    graph = { color = colors.blue },
    icon = { string = icon, padding_left = settings.paddings, padding_right = settings.paddings },
    -- Negative padding pulls the label back over the graph region instead of
    -- reserving a slot beside it, so the chip stays narrow.
    label = { string = title .. " ??%", align = "left", padding_left = -GRAPH_W, y_offset = 1 },
  })
  local bracket = sbar.add("bracket", "widgets.sys." .. id .. ".bracket", { graph.name }, {
    background = { color = colors.bg1, border_color = colors.blue, border_width = 1 },
  })
  sbar.add("item", "widgets.sys." .. id .. ".pad", { position = "right", width = settings.paddings })
  return { graph = graph, bracket = bracket, title = title }
end

local stats = {
  add_stat("ram", icons.ram, "ram"),
  add_stat("disk", icons.disk, "disk"),
  add_stat("gpu", icons.gpu, "gpu"),
}

-- One exec per tick emits "ram disk gpu" as whole-number percentages.
local stats_cmd = [[
ram=$(memory_pressure 2>/dev/null | awk '/free percentage/{gsub(/%/,"",$NF); print 100-$NF}')
disk=$(df / | awk 'NR==2{gsub(/%/,"",$5); print $5}')
gpu=$(ioreg -r -d 1 -w 0 -c IOAccelerator 2>/dev/null | grep -o '"Device Utilization %"=[0-9]*' | head -1 | grep -o '[0-9]*$')
printf '%s %s %s' "${ram:-0}" "${disk:-0}" "${gpu:-0}"
]]

local function push_stat(stat, v)
  local color = load_color(v)
  stat.graph:push({ v / 100. })
  stat.graph:set({ graph = { color = color }, label = stat.title .. " " .. v .. "%" })
  stat.bracket:set({ background = { border_color = color } })
end

local function update_all()
  sbar.exec(stats_cmd, function(out)
    local r, d, g = tostring(out):match("(%d+)%s+(%d+)%s+(%d+)")
    if not r then return end
    push_stat(stats[1], tonumber(r))
    push_stat(stats[2], tonumber(d))
    push_stat(stats[3], tonumber(g))
  end)
end

local driver = stats[1].graph
driver:set({ update_freq = 5 })
driver:subscribe("routine", update_all)
driver:subscribe("forced", update_all)
driver:subscribe("system_woke", update_all)

for _, stat in ipairs(stats) do
  stat.graph:subscribe("mouse.clicked", function(_)
    sbar.exec("open -a 'Activity Monitor'")
  end)
end

sbar.add("item", "widgets.sys.padding", { position = "right", width = settings.group_paddings })
