#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$SRC_DIR/config"
WALLPAPER_SRC="$SRC_DIR/Pictures/wallpapers"

echo "Source: $SRC_DIR"

run() {
  echo "  $*"
  "$@"
}

backup_dir() {
  local target="$1"
  if [ -e "$target" ]; then
    local bak="${target}.bak-$(date +%s)"
    run mv "$target" "$bak"
    echo "  -> backed up existing to $bak"
  fi
}

echo "Installing dotfiles to ~/.config:"
for app_dir in "$CONFIG_SRC"/*/; do
  [ -d "$app_dir" ] || continue
  app="$(basename "$app_dir")"
  target="$HOME/.config/$app"
  backup_dir "$target"
  run cp -r "$app_dir" "$target"
  echo "  -> installed $app -> $target"
done

echo "Fixing hardcoded paths"
for app_dir in "$CONFIG_SRC"/*/; do
  [ -d "$app_dir" ] || continue
  app="$(basename "$app_dir")"
  while IFS= read -r -d '' f; do
    if grep -q '/home/nrxg' "$f" 2>/dev/null; then
      run sed -i "s|/home/nrxg|\$HOME|g" "$f"
      echo "  -> patched $f"
    fi
  done < <(find "$HOME/.config/$app" -type f -not -name 'current_wallpaper' -print0)
done

echo "wallpapers to ~/Pictures/wallpapers"
WALL_TARGET="$HOME/Pictures/wallpapers"
mkdir -p "$WALL_TARGET"
WALL_COUNT=0
for img in "$WALLPAPER_SRC"/*; do
  [ -f "$img" ] || continue
  name="$(basename "$img")"
  if [ -e "$WALL_TARGET/$name" ]; then
    backup_dir "$WALL_TARGET/$name"
  fi
  run cp "$img" "$WALL_TARGET/$name"
  WALL_COUNT=$((WALL_COUNT + 1))
done
echo "  -> $WALL_COUNT wallpapers -> $WALL_TARGET"

echo "cureent wp symlink"
SYMLINK="$HOME/.config/hypr/current_wallpaper"
run mkdir -p "$(dirname "$SYMLINK")"
if [ -e "$SYMLINK" ] && [ ! -L "$SYMLINK" ]; then
  backup_dir "$SYMLINK"
fi
run ln -sf "$CONFIG_SRC/hypr/current_wallpaper" "$SYMLINK"
echo "  -> $SYMLINK -> $CONFIG_SRC/hypr/current_wallpaper"

echo "Done."
