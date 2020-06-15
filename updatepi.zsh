#!/bin/zsh

#
# updatepi.zsh
#
# Update local Pi user config files
# (eg. between multiple machines)
#
# @author    Tony Smith
# @copyright 2019-20, Tony Smith
# @version   2.1.2
# @license   MIT
#

file_source="$HOME/GitHub/dotfiles"

if [[ ! -e "$file_source" ]]; then
    echo "Please clone the repo 'dotfiles' before proceeding -- exiting "
    exit 1
fi

echo "Updating primary config files... "

# nano rc file
cp -v "$file_source/pi_nanorc" "$HOME/.nanorc"

# bash profile
cp -v "$file_source/pi_bash_aliases" "$HOME/.bash_aliases"

# FROM 2.0.0
# Sync .zshrc
cp -v "$file_source/pi_zshrc" "$HOME/.zshrc"

# gitup config
if [[ ! -e "$file_source/.config/gitup" ]]; then
    echo "Adding ~/.config/gitup... "
    mkdir -p "$file_source/.config/gitup"
fi

cp -v "$file_source/pi_bookmarks" "$HOME/.config/gitup/bookmarks"

if [[ ! -e "$HOME/.config/git" ]]; then
    echo "Adding ~/.config/git... "
    mkdir -p "$HOME/.config/git"
fi

# git global exclude file
if cp -v "$file_source/gitignore_global" "$HOME/.config/git/gitignore_global"; then
    # Add a reference to the file to git (assumes git installed)
    git config --global core.excludesfile "$HOME/.config/git/gitignore_global"
fi

echo "Pi configuration files updated"
