#!/bin/bash

step=5
msgTag="volume"

ID_FILE="$HOME/.config/hypr/volume_id"

case "$1" in
    up)
        volume=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}' | head -n1 | tr -d '%')
        echo "$volume"
        if [ "$volume" -lt 100 ]; then
            pactl set-sink-volume @DEFAULT_SINK@ +${step}%
        fi
        ;;
    down)
        volume=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}' | head -n1 | tr -d '%')
        if [ "$volume" -ge 0 ]; then
            pactl set-sink-volume @DEFAULT_SINK@ -${step}%
        fi
        ;;
    mute)
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        ;;
esac
