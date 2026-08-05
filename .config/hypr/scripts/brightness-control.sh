#!/bin/bash

step=10
msgTag="brightness"

ID_FILE="$HOME/.config/hypr/brightness_id"

current=$(brightnessctl g)
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
