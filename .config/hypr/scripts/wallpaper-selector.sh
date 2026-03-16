#!/bin/bash
# Wallpaper selector using rofi and swww

WALLPAPER_DIR="$HOME/.config/hypr/wallpaper"

# Check if wallpaper directory exists
if [ ! -d "$WALLPAPER_DIR" ]; then
    notify-send "Error" "Wallpaper directory not found: $WALLPAPER_DIR"

    exit 1
fi

# Get list of image files
images=()
while IFS= read -r -d '' file; do
    images+=("$file")
done < <(find -L "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) -print0)

# Check if any images were found
if [ ${#images[@]} -eq 0 ]; then
    notify-send "Error" "No images found in $WALLPAPER_DIR"

    exit 1
fi

# Create a list of basename paths for rofi
options=()
for img in "${images[@]}"; do
    options+=("$(basename "$img")")
done

# Show rofi selector
selected=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "Select Wallpaper" -i)

if [ -n "$selected" ]; then
    # Find the full path of the selected image
    for img in "${images[@]}"; do
        if [ "$(basename "$img")" = "$selected" ]; then
            # Apply wallpaper using swww
            swww img "$img" \
                --transition-type random \
                --transition-duration 1.5 \
                --transition-fps 60
            
            notify-send "Wallpaper Changed" "Selected: $selected" --urgency=low

            break
        fi
    done
fi
