#!/bin/bash

EXTERNAL=$(hyprctl monitors -j | jq -r '.[] | select(.name != "eDP-1") | .name' | head -1)

if [ -z "$EXTERNAL" ]; then
    EXTERNAL="eDP-1"
fi

for i in {11..20}; do
    hyprctl keyword workspace "$i, monitor:$EXTERNAL, persistent:true" 2>/dev/null
done

notify-send "Hyprland" "Workspaces 11-20 bound to $EXTERNAL" 2>/dev/null || true
