#!/bin/bash

step=10
msgTag="brightness"

ID_FILE="$HOME/.config/hypr/brightness_id"

current=$(brightnessctl g)
max=$(brightnessctl m)
percent=$(( current * 100 / max ))


case "$1" in
    up)
        brightnessctl s "$step%+"
        ;;
    down)
        brightnessctl s "$step%-"
        ;;
    max)
        brightnessctl s 100%
        ;;
    min)
        brightnessctl s 1%
        ;;
    *)
        echo "Usage: $0 {up|down|max|min}"
        exit 1
        ;;
esac

current=$(brightnessctl g)
percent=$(( current * 100 / max ))


if [ -f "$ID_FILE" ]; then
    notif_id=$(cat "$ID_FILE")
else
    notif_id=0
fi

if (( current < 30 )); then icon="audio-volume-low"
elif (( current < 70 )); then icon="audio-volume-medium"
else icon="audio-volume-high"
fi
text="$percent%"

new_id=$(notify-send -r "$notif_id" -u low -i "display" "Brightness" "$text" -p | head -n1)

echo "$new_id" > "$ID_FILE"
