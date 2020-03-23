#!/usr/bin/env bash

#
# updatemac.sh
#
# Update local Macs user config files
# (eg. between multiple machines)
#
# @author    Tony Smith
# @copyright 2019-20, Tony Smith
# @version   2.0.0
# @license   MIT
#


source="$HOME/documents/github/dotfiles"
target="$HOME/Library"

if ! [ -e "$source" ]; then
    echo "Please clone the repo \'dotfiles\' before proceeding -- exiting "
    exit 1
fi

# Process any arguments
# NOTE P == Partial, ie. only update frequently used app configs
#      F == Full, ie. update frequently used app configs AND apply
#           macOS configurations AND occasional use app configs
choice="ASK"
for arg in "$@"; do
    theArg=${arg^^*}
    if [[ $theArg = "-F" || $theArg = "--FULL" ]]; then
        choice="F"
    elif [[ $theArg = "-P" || $theArg = "--PARTIAL" ]]; then
        choice="P"
    fi
done

# No valid arguments passed, so ask the user for the type of update

if [ "$choice" = "ASK" ]; then
    read -n 1 -s -p "Full [F] or partial [P] update? " choice
    if [ -z "$choice" ]; then
        echo "Cancelling..."
        exit 0
    fi
fi

choice=${choice^^*}
if [[ "$choice" != "F" && "$choice" != "P" ]]; then
    echo "Invalid option selected: '$choice' -- cancelling... "
    exit 1
fi

# The following are items that are likely to change often
echo "Updating primary config files... "

# nano rc file
cp -v "$source/nanorc" "$HOME/.nanorc"

# bash profile
cp -v "$source/bash_profile" "$HOME/.bash_profile"

# vscode settings
cp -v "$source/vs_settings.json" "$target/Application Support/Code/User/settings.json"

# gitup config
if ! [ -e "$HOME/.config/gitup" ]; then
    echo "Adding ~/.config/gitup... "
    mkdir -p "$HOME/.config/gitup"
fi
cp -v "$source/bookmarks" "$HOME/.config/gitup/bookmarks"

if ! [ -e "$HOME/.config/git" ]; then
    echo "Adding ~/.config/git... "
    mkdir -p "$HOME/.config/git"
fi

# git global exclude file
# Added it to partial install in 1.0.3
if cp -v "$source/gitignore_global" "$HOME/.config/git/gitignore_global"; then
    # Add a reference to the file to git (assumes git installed)
    git config --global core.excludesfile "$HOME/.config/git/gitignore_global"
fi

# The following are items that won't be overwritten. They are very, very unlikely
# to be changed once installed in the first place
if [ "$choice" = "F" ]; then
    echo "Updating additional config files... "
    # FROM 1.2.0 -- Don't copy FFMPEG under Catalina
    # cp -nvR "$source/ffmpeg/" "$target/ffmpeg"
    cp -nvR "$source/Services/Copy File Path.workflow" "$target/Services/Copy File Path.workflow"

    # FROM 1.2.1 -- fix duplication of files vs folders
    cp -nvR "$source/LaunchAgents/" "$target/LaunchAgents"
    cp -nvR "$source/Quicklook/" "$target/Quicklook"

    # FROM 1.3.0 -- add ~/Library/Filters folder (custom Quartz filters)
    cp -nvR "$source/Filters/" "$target/Filters"

    # FROM 1.1.0 -- Don't bother with BBEdit for now
    # cp -nvR "$source/bbedit_squirrel.plist" "$target/Application Support/BBEdit/Language Modules/Squirrel.plist"

    # FROM 1.5.0 -- Add 64-bit libdvdcss
    cp -nv "$source/libdvdcss/libdvdcss.2.dylib" "/usr/local/lib/libdvdcss.2.dylib"

    # FROM 1.4.0 -- Add second terminal file (HomebrewMeDark)
    cp -nv "$source/HomebrewMe.terminal" "$HOME/Desktop/HomebrewMe.terminal"
    cp -nv "$source/HomebrewMeDark.terminal" "$HOME/Desktop/HomebrewMeDark.terminal"
    echo "Terminal settings files 'HomebrewMe' and 'HomebrewMeDark' copied to desktop. To use them, open Terminal > Preferences > Profiles and import"

    cp -nv "$source/pixelmator_shapes.pxs" "$HOME/Desktop/pixelmator_shapes.pxs"
    echo "Pixelmater shapes file 'pixelmator_shapes.pxs' copied to desktop. To use it, open Pixelmator > File > Import..."

    # FROM 1.1.0
    # Run the various macOS config scriptlets
    echo "Configuring macOS... "
    cd "$source/config"
    for task in *; do
        echo $task
        . "$task"
    done
fi

echo "Configuration files updated"


