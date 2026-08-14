-- Extra autostart processes.

-- Workspaces 11-20 are now bound natively in monitors.lua, so
-- scripts/setup-external-workspaces.sh is no longer launched here.
--
-- swaync is not started either: Omarchy 4 draws notifications from its own
-- shell process (omarchy-launch-shell), so running a second daemon would
-- double up every notification.

o.exec_on_start("[workspace 11 silent] ghostty -e tmux new -A -s Home")
o.exec_on_start("[workspace 12 silent] zen-browser")
