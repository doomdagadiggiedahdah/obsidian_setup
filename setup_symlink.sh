#!/bin/bash

DIR_LOCATION="$HOME/Documents/obsidian_setup" # replace this with this repo's location
OBS_LOCATION="$HOME/Obsidian"                 # replace this with your Obsidian root folder

# Create symlinks
ln -sfn "${DIR_LOCATION}/snippets" "${OBS_LOCATION}/.obsidian/snippets"
ln -sfn "${DIR_LOCATION}/Templates" "${OBS_LOCATION}/Templates"
ln -sf "${DIR_LOCATION}/week review checklist.md" "${OBS_LOCATION}/ZettleKasten/week review checklist.md"


echo "Symlinks created!"
