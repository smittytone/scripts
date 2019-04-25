#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash

# Update user config files
# Version 1.0.0

source=~/documents/github/dotfiles

if ! [ -e "$source" ]; then
    echo "Please clone the repo \"dotfiles\" -- exiting "
    exit 1
fi

read -n 1 -s -p "All [A] or partial [P] update? " choice
if [ -z "$choice" ]; then
    echo
    echo "Cancelling..."
    exit 0
fi

choice=${choice^^*}

if [[ "$choice" != "A" && "$choice" != "P" ]]; then
    echo
    echo "Invalid option selected ($choice) -- cancelling... "
    exit 0
fi

echo "Updating primary config files... "
cp -v  "$source"/nanorc "$HOME"/.nanorc
cp -v  "$source"/bash_profile "$HOME"/.bash_profile

if ! [ -e "$HOME"/.config ]; then
    echo "Adding ~/.config... "
    mkdir "$HOME"/.config
fi

if ! [ -e "$HOME"/.config/gitup ]; then
    echo "Adding ~/.config/gitup... "
    mkdir "$HOME"/.config/gitup
fi

cp -v "$source"/bookmarks "$HOME"/.config/gitup/bookmarks;

if [ "$choice" = "A" ]; then
    echo "Updating additional config files... "
    target="$HOME/Library"
    cp -nvR "$source"/Services/'Copy File Path'.workflow "$target"/Services/'Copy File Path'.workflow
    cp -nvR "$source"/LaunchAgents "$target"/LaunchAgents
    cp -nvR "$source"/Quicklook "$target"/Quicklook
    cp -nvR "$source"/vs_settings.json "$target"/'Application Support'/Code/User/settings.json

    echo "Adding ~/.config/git... "
    if ! [ -e "$HOME"/.config/git ]; then
        mkdir ~/.config/githup
    fi

    if cp -nv "$source"/gitignore_global "$HOME"/.config/git/gitignore_global; then
        git config --global core.excludesfile "$HOME"/.config/git/gitignore_global
    fi

    cp -nv "$source"/HomebrewMe.terminal "$HOME"/Desktop/HomebrewMe.terminal
    echo "Terminal settings file 'HomebrewMe' copied to desktop. To use it, open Terminal > Preferences > Profiles and import"
fi

echo Done
