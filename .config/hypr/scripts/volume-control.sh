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

volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]\+%' | head -n1 | tr -d '%')
mute=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')

echo "$volume"
echo "$mute"

if [ -f "$ID_FILE" ]; then
    notif_id=$(cat "$ID_FILE")
else
    notif_id=0
fi

if [[ "$mute" == "yes" || "$volume" -eq 0 ]]; then
    echo "muted"
    icon="audio-volume-muted"
    text="Muted"
else
    if (( volume < 30 )); then icon="audio-volume-low"
    elif (( volume < 70 )); then icon="audio-volume-medium"
    else icon="audio-volume-high"
    fi
    text="$volume%"
fi

new_id=$(notify-send -r "$notif_id" -u low -i "$icon" "Volume" "$text" -p | head -n1)

echo "$new_id" > "$ID_FILE"
