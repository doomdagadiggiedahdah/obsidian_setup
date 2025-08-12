#!/bin/bash

# Obsidian to Quartz Publisher
# Usage: ./obsidian-to-quartz.sh "/path/to/obsidian/note.md"

set -e

# Configuration
OBSIDIAN_PATH="$HOME/Obsidian"
QUARTZ_PATH="$HOME/Documents/blogg"
CONTENT_DIR="$QUARTZ_PATH/content/blog"
IMAGES_DIR="$QUARTZ_PATH/content"
PREVIEW_URL="http://localhost:1323"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Cleanup function
cleanup() {
    if [ ! -z "$QUARTZ_PID" ]; then
        print_status "Stopping Quartz server..."
        kill $QUARTZ_PID 2>/dev/null || true
        wait $QUARTZ_PID 2>/dev/null || true
    fi
}

# Set up trap for cleanup
trap cleanup EXIT

# Check if file path is provided
if [ -z "$1" ]; then
    print_error "Usage: $0 <obsidian-file-path>"
    exit 1
fi

OBSIDIAN_FILE="$1"

# Validate input file
if [ ! -f "$OBSIDIAN_FILE" ]; then
    print_error "File not found: $OBSIDIAN_FILE"
    exit 1
fi

# Extract filename without extension
FILENAME=$(basename "$OBSIDIAN_FILE" .md)
OBSIDIAN_DIR=$(dirname "$OBSIDIAN_FILE")

print_status "Processing: $FILENAME"

# Create content directory if it doesn't exist
mkdir -p "$CONTENT_DIR"
mkdir -p "$IMAGES_DIR"

# Copy markdown file to Quartz content directory
DEST_FILE="$CONTENT_DIR/$FILENAME.md"
cp "$OBSIDIAN_FILE" "$DEST_FILE"
print_status "Copied markdown file to: $DEST_FILE"

# Array to store copied image files for potential cleanup
COPIED_IMAGES=()

# Parse and copy images
print_status "Processing images..."

# Function to copy image and update reference
process_image() {
    local image_ref="$1"
    local image_file=""
    
    # Handle Obsidian wikilinks ![[image.png]]
    if [[ $image_ref =~ !\[\[([^]]+)\]\] ]]; then
        image_file="${BASH_REMATCH[1]}"
    # Handle standard markdown ![](image.png)
    elif [[ $image_ref =~ !\[[^]]*\]\(([^\)]+)\) ]]; then
        image_file="${BASH_REMATCH[1]}"
    fi
    
    if [ ! -z "$image_file" ]; then
        # Remove any path components, just use filename
        image_basename=$(basename "$image_file")
        
        # Look for image in Obsidian directory and subdirectories
        SOURCE_IMAGE=""
        if [ -f "$OBSIDIAN_DIR/$image_file" ]; then
            SOURCE_IMAGE="$OBSIDIAN_DIR/$image_file"
        elif [ -f "$OBSIDIAN_PATH/$image_file" ]; then
            SOURCE_IMAGE="$OBSIDIAN_PATH/$image_file"
        else
            # Search for the image in common Obsidian attachment folders
            for search_dir in "$OBSIDIAN_PATH/Files" "$OBSIDIAN_PATH/assets" "$OBSIDIAN_PATH"; do
                if [ -f "$search_dir/$image_basename" ]; then
                    SOURCE_IMAGE="$search_dir/$image_basename"
                    break
                fi
            done
        fi
        
        if [ ! -z "$SOURCE_IMAGE" ] && [ -f "$SOURCE_IMAGE" ]; then
            # Copy image to Quartz images directory
            DEST_IMAGE="$IMAGES_DIR/$image_basename"
            cp "$SOURCE_IMAGE" "$DEST_IMAGE"
            COPIED_IMAGES+=("$DEST_IMAGE")
            print_status "Copied image: $image_basename"
            
            # Update the markdown file to use the new image path
            if [[ $image_ref =~ !\[\[([^]]+)\]\] ]]; then
                # Keep wikilink format, just update the filename
                sed -i "s|!\[\[$image_file\]\]|![[$image_basename]]|g" "$DEST_FILE"
            else
                # Update existing markdown links to use just the filename
                sed -i "s|!\[[^]]*\]($image_file)|![]($image_basename)|g" "$DEST_FILE"
            fi
        else
            print_warning "Image not found: $image_file"
        fi
    fi
}

# Find all image references in the markdown file
while IFS= read -r line; do
    # Find Obsidian wikilinks
    while [[ $line =~ (!\[\[[^]]+\]\]) ]]; do
        process_image "${BASH_REMATCH[1]}"
        line="${line/${BASH_REMATCH[1]}/}"
    done
    
    # Find standard markdown images
    while [[ $line =~ (!\[[^]]*\]\([^\)]+\)) ]]; do
        process_image "${BASH_REMATCH[1]}"
        line="${line/${BASH_REMATCH[1]}/}"
    done
done < "$OBSIDIAN_FILE"

# Change to Quartz directory
cd "$QUARTZ_PATH"

print_status "Building and serving Quartz..."

# Start Quartz build and serve
npx quartz build --serve --port 1323 > /dev/null 2>&1 &
QUARTZ_PID=$!

# Wait a moment for server to start
sleep 3

# Check if server is running
if ! kill -0 $QUARTZ_PID 2>/dev/null; then
    print_error "Failed to start Quartz server"
    exit 1
fi

print_status "Quartz server started (PID: $QUARTZ_PID)"

# Open browser
if command -v xdg-open > /dev/null; then
    xdg-open "$PREVIEW_URL" > /dev/null 2>&1
elif command -v open > /dev/null; then
    open "$PREVIEW_URL" > /dev/null 2>&1
else
    print_warning "Could not open browser automatically. Please visit: $PREVIEW_URL"
fi

print_status "Preview available at: $PREVIEW_URL"

# Prompt user for publishing decision
echo
while true; do
    read -p "Do you want to publish this to your blog? (Y/n): " yn
    case $yn in
        [Yy]* | "" )
            print_status "Publishing to blog..."
            
            # Git operations
            git add .
            git commit -m "Add post: $FILENAME"
            git push
            
            print_status "Successfully published!"
            break
            ;;
        [Nn]* )
            print_status "Not publishing."
            break
            ;;
        * )
            echo "Please answer yes (Y) or no (n)."
            ;;
    esac
done

print_status "Done!"
