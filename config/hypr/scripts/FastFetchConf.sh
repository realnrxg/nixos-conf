#!/usr/bin/env bash
IFS=$'\n\t'

# Define directories
fastfetch_configs="$HOME/.config/fastfetch/configs"
fastfetch_icons="$HOME/.config/fastfetch/icons"
fastfetch_config="$HOME/.config/fastfetch/config.jsonc"
rofi_config="$HOME/.config/rofi/config.rasi"
msg=' Choose Fastfetch Config '

# Function to display menu options with icons
menu() {
    while IFS= read -r file; do
        filename=$(basename "$file")
        base="${filename%.*}"

        # Look for matching image in the icons folder
        icon=""
        for ext in png jpg jpeg gif; do
            if [[ -f "$fastfetch_icons/$base.$ext" ]]; then
                icon="$fastfetch_icons/$base.$ext"
                break
            fi
        done

        # Output with icon format for rofi
        if [[ -n "$icon" ]]; then
            printf '%s\0icon\x1f%s\n' "$filename" "$icon"
        else
            printf '%s\n' "$filename"
        fi
    done < <(find -L "$fastfetch_configs" -maxdepth 1 -type f \( -name "*.jsonc" -o -name "*.json" \) -exec basename {} \; | sort)
}

# Apply selected configuration
apply_config() {
    ln -sf "$fastfetch_configs/$1" "$fastfetch_config"
}

# Main function
main() {
    choice=$(menu | rofi -dmenu -i -show-icons -config "$rofi_config" -mesg "$msg")
    if [[ -z "$choice" ]]; then
        echo "No option selected. Exiting."
        exit 0
    fi
    apply_config "$choice"
}

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

main
