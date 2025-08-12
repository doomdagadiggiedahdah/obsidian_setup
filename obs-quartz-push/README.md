# Obsidian to Quartz Publisher

A script that seamlessly publishes Obsidian notes to your Quartz blog with image handling and preview functionality.

## Setup

### 1. Install Shell Commands Plugin in Obsidian

1. Open Obsidian Settings
2. Go to Community Plugins
3. Search for "Shell Commands"
4. Install and enable the plugin

### 2. Configure Shell Commands Plugin

1. In Obsidian Settings, go to Shell Commands
2. Click "New command"
3. Set the command to:
   ```bash
   /home/mat/Documents/ProgramExperiments/obs-quartz-push/obsidian-to-quartz.sh "{{file_path:absolute}}"
   ```
4. Set the alias to: `Prepare publish`
5. Enable "Output channel" to "Notification"

### 3. Make Script Executable

Run this command to make the script executable:
```bash
chmod +x /home/mat/Documents/ProgramExperiments/obs-quartz-push/obsidian-to-quartz.sh
```

## Usage

1. Open any note in Obsidian
2. Run the command "Prepare publish" (via Command Palette or hotkey)
3. The script will:
   - Copy your note and images to the Quartz repo
   - Build and serve Quartz locally
   - Open your browser to preview
   - Prompt you to publish (Y/n)
   - If Y: commit and push to git
   - If n: clean up the copied files

## Features

- ✅ Handles both Obsidian wikilinks `![[image.png]]` and markdown `![](image.png)`
- ✅ Searches multiple locations for images
- ✅ Converts wikilinks to standard markdown
- ✅ Local preview before publishing
- ✅ Git integration with commit/push
- ✅ Cleanup option if you don't want to publish
- ✅ Colored terminal output
- ✅ Process management (kills server on exit)

## Configuration

Edit the script to change paths:
- `OBSIDIAN_PATH`: Your Obsidian vault location
- `QUARTZ_PATH`: Your Quartz blog repository
- `CONTENT_DIR`: Where blog posts go
- `IMAGES_DIR`: Where images are stored