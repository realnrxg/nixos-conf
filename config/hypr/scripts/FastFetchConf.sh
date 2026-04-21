#!/usr/bin/env bash
# Created by nrxg (github.com/realnrxg)
# Original style and how to do it by JaKooLit (https://github.com/JaKooLit)

IFS=$'\n\t'

fastfetch_configs="$HOME/.config/fastfetch/configs"
fastfetch_config="$HOME/.config/fastfetch/config.jsonc"
rofi_config="$HOME/.config/rofi/config.rasi"
msg='Choose Fastfetch Config'

menu() {
    options=()
    while IFS= read -r file; do
        options+=("$(basename "$file")")
    done < <(find -L "$fastfetch_configs" -maxdepth 1 -type f -exec basename {} \; | sort)
    printf '%s\n' "${options[@]}"
}

apply_config() {
    ln -sf "$fastfetch_configs/$1" "$fastfetch_config"
}

main() {
    choice=$(menu | rofi -i -dmenu -config "$rofi_config" -mesg "$msg")
    if [[ -z "$choice" ]]; then
        echo "No option selected. Exiting."
        exit 0
    fi
    apply_config "$choice"
}

if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

main
