#!/bin/zsh

#
# updatepi.zsh
#
# Update local Pi user config files
# (eg. between multiple machines)
#
# @author    Tony Smith
# @copyright 2019-20, Tony Smith
# @version   3.0.0
# @license   MIT
#

file_source="$HOME/GitHub/dotfiles"

if [[ ! -e "$file_source" ]]; then
    echo "Please clone the repo 'dotfiles' before proceeding -- exiting "
    exit 1
fi

echo "Updating primary config files... "

# nano rc file
cp -v "$file_source/Pi/nanorc" "$HOME/.nanorc"

# bash profile
cp -v "$file_source/Pi/bash_aliases" "$HOME/.bash_aliases"

# FROM 2.0.0
# Sync .zshrc
cp -v "$file_source/Pi/zshrc" "$HOME/.zshrc"

# FROM 4.0.0
# pylint rc file
cp -v "$file_source/Universal/pylintrc" "$HOME/.pylintrc"

# gitup config
# FROM 3.0.0 fix location
if [[ ! -e "$HOME/.config/gitup" ]]; then
    echo "Adding ~/.config/gitup... "
    mkdir -p "$HOME/.config/gitup"
fi

cp -v "$file_source/Pi/bookmarks" "$HOME/.config/gitup/bookmarks"

if [[ ! -e "$HOME/.config/git" ]]; then
    echo "Adding ~/.config/git... "
    mkdir -p "$HOME/.config/git"
fi

# git global exclude file
if cp -v "$file_source/Universal/gitignore_global" "$HOME/.config/git/gitignore_global"; then
    # Add a reference to the file to git (assumes git installed)
    git config --global core.excludesfile "$HOME/.config/git/gitignore_global"
fi

echo "Pi configuration files updated"
