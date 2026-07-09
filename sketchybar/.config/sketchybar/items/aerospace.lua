-- Only what this config needs: the currently focused AeroSpace workspace.
-- Deliberately NOT porting upstream falleco's get_workspaces()/get_monitors()/
-- get_workspaces_on_monitor()/etc -- this bar shows a FIXED 10 workspace
-- slots (see items/spaces.lua) matching this repo's aerospace `ctrl-1`..
-- `ctrl-0` bindings, not AeroSpace's lazily-created workspace list (verified
-- live: `aerospace list-workspaces --all` only returns workspaces already
-- visited, e.g. just "1"/"2" even with 10 keybindings configured). Also a
-- single-monitor Mac Mini, so no monitor-assignment helpers needed either.
function get_current_workspace()
  local file = io.popen("aerospace list-workspaces --focused")
  local result = file:read("*a")
  file:close()
  return (result:gsub("%s+$", ""))
end
