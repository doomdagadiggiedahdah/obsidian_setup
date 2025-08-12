#!/bin/bash

# Simple Obsidian to Quartz publisher
# Usage: ./simple-publish.sh "/path/to/note.md"

set -e

OBSIDIAN_PATH="$HOME/Obsidian"
QUARTZ_PATH="$HOME/Documents/blogg"
CONTENT_DIR="$QUARTZ_PATH/content/blog"

[ -z "$1" ] && { echo "Usage: $0 <file.md>"; exit 1; }
[ ! -f "$1" ] && { echo "File not found: $1"; exit 1; }

FILENAME=$(basename "$1" .md)

# Copy file
mkdir -p "$CONTENT_DIR"
cp "$1" "$CONTENT_DIR/$FILENAME.md"

# Copy images from Files directory
grep -o '!\[\[[^]]*\]\]' "$1" 2>/dev/null | while read -r img; do
    img_name=$(echo "$img" | sed 's/!\[\[\([^]]*\)\]\]/\1/')
    [ -f "$OBSIDIAN_PATH/Files/$img_name" ] && cp "$OBSIDIAN_PATH/Files/$img_name" "$CONTENT_DIR/"
done

# Build and serve
cd "$QUARTZ_PATH"
npx quartz build --serve --port 1323 &
sleep 2
echo "Preview: http://localhost:1323"
wait