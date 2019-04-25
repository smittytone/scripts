#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash
#      but I use brew-installed bash under macOS

# Update local user config files
# Version 1.0.1

source=~/documents/github/dotfiles

if ! [ -e "$source" ]; then
    echo "Please clone the repo \'dotfiles\' before proceeding-- exiting "
    exit 1
fi

read -n 1 -s -p "Full [F] or partial [P] update? " choice
if [ -z "$choice" ]; then
    echo -e "/nCancelling..."
    exit 0
fi

choice=${choice^^*}

if [[ "$choice" != "F" && "$choice" != "P" ]]; then
    echo -e "/nInvalid option selected ($choice) -- cancelling... "
    exit 0
fi

echo "Updating primary config files... "
cp -v "$source"/nanorc "$HOME"/.nanorc
cp -v "$source"/bash_profile "$HOME"/.bash_profile

if ! [ -e "$HOME"/.config ]; then
    echo "Adding ~/.config... "
    mkdir "$HOME"/.config
fi

if ! [ -e "$HOME"/.config/gitup ]; then
    echo "Adding ~/.config/gitup... "
    mkdir "$HOME"/.config/gitup
fi

cp -v "$source"/bookmarks "$HOME"/.config/gitup/bookmarks;

if [ "$choice" = "F" ]; then
    echo "Updating additional config files... "
    # These are items that won't be overwritten
    target="$HOME/Library"
    cp -nvR "$source"/Services/'Copy File Path'.workflow "$target"/Services/'Copy File Path'.workflow
    cp -nvR "$source"/LaunchAgents "$target"/LaunchAgents
    cp -nvR "$source"/Quicklook "$target"/Quicklook
    cp -nvR "$source"/vs_settings.json "$target"/'Application Support'/Code/User/settings.json

    echo "Adding ~/.config/git... "
    if ! [ -e "$HOME"/.config/git ]; then
        mkdir ~/.config/git
    fi

    if cp -nv "$source"/gitignore_global "$HOME"/.config/git/gitignore_global; then
        # Add a reference to the file to git (assumes git installed)
        git config --global core.excludesfile "$HOME"/.config/git/gitignore_global
    fi

    cp -nv "$source"/HomebrewMe.terminal "$HOME"/Desktop/HomebrewMe.terminal
    echo "Terminal settings file 'HomebrewMe' copied to desktop. To use it, open Terminal > Preferences > Profiles and import"
fi

echo Done
