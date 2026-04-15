#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
SYMLINK_PATH="$HOME/.config/hypr/current_wallpaper"

cd "$WALLPAPER_DIR" || exit 1

SELECTED_WALL=$(find . -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.gif" \) \
  | sed 's|^\./||' \
  | sort -r \
  | while read -r a; do
      echo -en "$a\0icon\x1f$a\n"
    done \
  | rofi -dmenu -p "Wallpaper")

[ -z "$SELECTED_WALL" ] && exit 0

SELECTED_PATH="$WALLPAPER_DIR/$SELECTED_WALL"

# --- generate colors (fully non-interactive) ---
matugen image "$SELECTED_PATH" --mode dark --type scheme-tonal-spot --source-color-index 0 || {
  echo "matugen failed" | tee /tmp/matugen_error.log
  exit 1
}

# --- set wallpaper ---
awww img "$SELECTED_PATH" --transition-type any

# --- symlink ---
mkdir -p "$(dirname "$SYMLINK_PATH")"
ln -sf "$SELECTED_PATH" "$SYMLINK_PATH"
