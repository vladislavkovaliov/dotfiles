#!/usr/bin/env bash

#pkill waybar

#hyprctl dispatch exec waybar


while inotifywait -e close_write ~/.config/waybar; do killall -SIGUSR2 waybar; done
