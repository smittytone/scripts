#!/bin/zsh

# Set up key directories
file_source="$HOME/GitHub/dotfiles"
file_target="$HOME/Library"

# Run the various macOS config scriptlets
echo "Configuring macOS... "
if cd "$file_source/Mac/config"; then
    chmod +x ./*
    for task in *; do
        echo $task
        ./$task
    done
fi

# Restart Finder and Dock to effect changes
killall Finder Dock