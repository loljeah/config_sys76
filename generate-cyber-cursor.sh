#!/usr/bin/env bash
# Generate cyber-cursor theme: Green with purple outline
# Run this script after installing imagemagick and xcursorgen
# Usage: ./generate-cyber-cursor.sh

set -euo pipefail

CURSOR_NAME="cyber-cursor"
CURSOR_DIR="$HOME/.local/share/icons/$CURSOR_NAME/cursors"
THEME_DIR="$HOME/.local/share/icons/$CURSOR_NAME"
WORK_DIR="/tmp/cyber-cursor-build"
CURSOR_SIZE=32

# Colors (green body, purple outline)
FILL_COLOR="#00ff00"       # Bright green
OUTLINE_COLOR="#9900ff"    # Purple

echo "Creating cyber-cursor theme..."

# Create directories
mkdir -p "$CURSOR_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Create index.theme
cat > "$THEME_DIR/index.theme" << EOF
[Icon Theme]
Name=$CURSOR_NAME
Comment=Green cursor with purple outline (cyberpunk style)
Inherits=Adwaita
EOF

# Generate cursor images using ImageMagick
# Main arrow cursor
generate_cursor() {
    local name="$1"
    local hotx="$2"
    local hoty="$3"
    local svg_content="$4"

    # Create SVG
    echo "$svg_content" > "${name}.svg"

    # Convert SVG to PNG at multiple sizes
    # Prefer rsvg-convert (handles transparency correctly), fallback to ImageMagick
    for size in 24 32 48 64; do
        if command -v rsvg-convert &>/dev/null; then
            rsvg-convert -w "$size" -h "$size" -o "${name}_${size}.png" "${name}.svg"
        else
            # ImageMagick fallback: -background none + PNG32 for RGBA
            magick -background none "${name}.svg" -resize "${size}x${size}" PNG32:"${name}_${size}.png"
        fi
    done

    # Create xcursor config
    cat > "${name}.cfg" << XCFG
24 $hotx $hoty ${name}_24.png
32 $hotx $hoty ${name}_32.png
48 $hotx $hoty ${name}_48.png
64 $hotx $hoty ${name}_64.png
XCFG

    # Generate X cursor
    xcursorgen "${name}.cfg" "$CURSOR_DIR/$name"
}

# Arrow cursor (left_ptr) - main pointer
ARROW_SVG='<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
  <path d="M 4 4 L 4 26 L 10 20 L 14 28 L 18 26 L 14 18 L 22 18 Z"
        fill="'"$FILL_COLOR"'" stroke="'"$OUTLINE_COLOR"'" stroke-width="2"/>
</svg>'
generate_cursor "left_ptr" 4 4 "$ARROW_SVG"

# Text cursor (xterm/ibeam)
TEXT_SVG='<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
  <path d="M 12 4 L 20 4 M 16 4 L 16 28 M 12 28 L 20 28"
        fill="none" stroke="'"$FILL_COLOR"'" stroke-width="3"/>
  <path d="M 12 4 L 20 4 M 16 4 L 16 28 M 12 28 L 20 28"
        fill="none" stroke="'"$OUTLINE_COLOR"'" stroke-width="1"/>
</svg>'
generate_cursor "xterm" 16 16 "$TEXT_SVG"

# Hand pointer (link/pointer)
HAND_SVG='<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
  <path d="M 10 8 L 10 20 L 8 20 L 8 24 L 24 24 L 24 14 L 22 14 L 22 10 L 18 10 L 18 6 L 14 6 L 14 10 L 10 10 Z"
        fill="'"$FILL_COLOR"'" stroke="'"$OUTLINE_COLOR"'" stroke-width="2"/>
</svg>'
generate_cursor "hand2" 10 8 "$HAND_SVG"
generate_cursor "pointer" 10 8 "$HAND_SVG"

# Crosshair
CROSS_SVG='<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
  <path d="M 16 4 L 16 28 M 4 16 L 28 16"
        fill="none" stroke="'"$FILL_COLOR"'" stroke-width="3"/>
  <path d="M 16 4 L 16 28 M 4 16 L 28 16"
        fill="none" stroke="'"$OUTLINE_COLOR"'" stroke-width="1"/>
</svg>'
generate_cursor "crosshair" 16 16 "$CROSS_SVG"

# Watch/wait cursor
WAIT_SVG='<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
  <circle cx="16" cy="16" r="10" fill="'"$FILL_COLOR"'" stroke="'"$OUTLINE_COLOR"'" stroke-width="2"/>
  <path d="M 16 10 L 16 16 L 20 16" fill="none" stroke="'"$OUTLINE_COLOR"'" stroke-width="2"/>
</svg>'
generate_cursor "watch" 16 16 "$WAIT_SVG"
generate_cursor "wait" 16 16 "$WAIT_SVG"

# Create symlinks for cursor aliases
cd "$CURSOR_DIR"

# Common aliases for left_ptr (arrow)
ln -sf left_ptr default
ln -sf left_ptr arrow
ln -sf left_ptr top_left_arrow

# Aliases for hand/pointer
ln -sf hand2 hand1
ln -sf hand2 pointing_hand
ln -sf pointer hand

# Aliases for text
ln -sf xterm text
ln -sf xterm ibeam

# Aliases for crosshair
ln -sf crosshair cross
ln -sf crosshair tcross

# Aliases for wait
ln -sf wait progress

# Use Adwaita fallback for cursors we didn't generate
# (resize handles, move, etc.)

echo ""
echo "Cyber-cursor theme created at: $THEME_DIR"
echo ""
echo "To activate:"
echo "  1. Log out and log back in, or"
echo "  2. Run: gsettings set org.gnome.desktop.interface cursor-theme '$CURSOR_NAME'"
echo "  3. Reload sway: swaymsg reload"
echo ""
echo "The theme inherits from Adwaita for cursors not explicitly defined."

# Cleanup
rm -rf "$WORK_DIR"
