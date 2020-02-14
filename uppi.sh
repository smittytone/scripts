#!/usr/bin/env bash

# Update local user config files (eg. between multiple machines)
# Version 1.0.0

source="$HOME/Documents/GitHub/dotfiles"
target="$HOME"

if ! [ -e "$source" ]; then
    echo "Please clone the repo \'dotfiles\' before proceeding -- exiting "
    exit 1
fi

# Process any arguments
# NOTE P == Partial, ie. only update frequently used app configs
#      F == Full, ie. update frequently used app configs AND apply
#           Pi system and occasional use app configs
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
cp -v "$source/pi_bash_aliases" "$HOME/.bash_aliases"


# gitup config
if ! [ -e "$HOME/.config/gitup" ]; then
    echo "Adding ~/.config/gitup... "
    mkdir -p "$HOME/.config/gitup"
fi
cp -v "$source/pi_bookmarks" "$HOME/.config/gitup/bookmarks"

if ! [ -e "$HOME/.config/git" ]; then
    echo "Adding ~/.config/git... "
    mkdir -p "$HOME/.config/git"
fi

# git global exclude file
# Added it to partial install in 1.0.0
if cp -v "$source/gitignore_global" "$HOME/.config/git/gitignore_global"; then
    # Add a reference to the file to git (assumes git installed)
    git config --global core.excludesfile "$HOME/.config/git/gitignore_global"
fi

echo "Configuration files updated"
