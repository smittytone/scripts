#!/usr/bin/env bash

# Update local user config files (eg. between multiple machines)
# Version 1.0.2

source="$HOME/Documents/GitHub/dotfiles"

if ! [ -e "$source" ]; then
    echo "Please clone the repo \'dotfiles\' before proceeding -- exiting "
    exit 1
fi

# The following are items that are likely to change often
echo "Updating primary config files... "

# nano rc file
cp -v "$source/nanorc" "$HOME/.nanorc"

# bash profile
cp -v "$source/pi_bash_aliases" "$HOME/.bash_aliases"

# FROM 1.0.2
# zsh profile
cp -v "$source/pi_zshrc" "$HOME/.zshrc"

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
