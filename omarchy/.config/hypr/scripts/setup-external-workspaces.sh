#!/bin/bash
# Detect external monitor and bind workspaces 11-20

if hyprctl monitors -j | jq -e '.[] | select(.name == "HDMI-A-1")' > /dev/null 2>&1; then
    EXTERNAL="HDMI-A-1"
elif hyprctl monitors -j | jq -e '.[] | select(.name == "DP-1")' > /dev/null 2>&1; then
    EXTERNAL="DP-1"
else
    EXTERNAL="eDP-1"
fi

for i in {11..20}; do
    hyprctl keyword workspace "$i, monitor:$EXTERNAL, persistent:true" 2>/dev/null
done

notify-send "Hyprland" "Workspaces 11-20 bound to $EXTERNAL" 2>/dev/null || true
