-- Only what this config needs: the currently focused AeroSpace workspace.
-- Deliberately NOT porting upstream falleco's get_workspaces()/get_monitors()/
-- get_workspaces_on_monitor()/etc -- this bar shows FIXED 20 workspace slots
-- (see items/spaces.lua) matching this repo's aerospace bindings (`cmd-1`..
-- `cmd-0` -> ws 1-10 on the primary display, `ctrl-1`..`ctrl-0` -> ws 11-20
-- on the external BenQ), not AeroSpace's lazily-created workspace list
-- (verified live: `aerospace list-workspaces --all` only returns workspaces
-- already visited, e.g. just "1"/"2" even with 20 keybindings configured).
-- The 20 slots are split by monitor via each item's `display` property in
-- spaces.lua (1-10 on display 1, 11-20 on display 2), so no dynamic
-- get_workspaces_on_monitor() helper is needed.
function get_current_workspace()
	local file = io.popen("aerospace list-workspaces --focused")
	local result = file:read("*a")
	file:close()
	return (result:gsub("%s+$", ""))
end
