#!/bin/bash

# Show all Hyprland keybindings as a notification
# https://wiki.hypr.land/Configuring/Binds/

binds=$(
    grep -E '^bind' ~/.config/hypr/conf/keybindings.conf \
    | sed -E 's/^bind[elm]* = //' \
    | sed -E 's/^(\$[a-zA-Z]+) (ALT|SHIFT),/\1+\2 /' \
    | sed -E 's/^(\$[a-zA-Z]+),/\1+ /' \
    | sed -E 's/^,\s*//' \
    | awk -F', ' '{printf "%-28s %s\n", $1, $2}'
)

notify-send -u low -i "input-keyboard" "Hyprland keybindings" "$binds"