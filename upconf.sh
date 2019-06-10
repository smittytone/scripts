#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash
#      but I use brew-installed bash under macOS

# Update local user config files (eg. between multiple machines)
# Version 1.0.5

source="$HOME/documents/github/dotfiles"
target="$HOME/Library"

if ! [ -e "$source" ]; then
    echo "Please clone the repo \'dotfiles\' before proceeding -- exiting "
    exit 1
fi

# Process any arguments
choice="ASK"
for arg in "$@"; do
    if [[ $arg = "-f" || $arg = "--full" ]]; then
        choice="F"
    elif [[ $arg = "-p" || $arg = "--partial" ]]; then
        choice="P"
    fi
done

if [ "$choice" = "ASK" ]; then
    read -n 1 -s -p "Full [F] or partial [P] update? " choice
    if [ -z "$choice" ]; then
        echo -e "\nCancelling..."
        exit 0
    fi
    choice=${choice^^*}
fi

if [[ "$choice" != "F" && "$choice" != "P" ]]; then
    echo -e "\nInvalid option selected: '$choice' -- cancelling... "
    exit 0
fi

# The following are items that are likely to change often
echo -e "\nUpdating primary config files... "

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
    cp -nvR "$source/Services/Copy File Path.workflow" "$target/Services/Copy File Path.workflow"
    cp -nvR "$source/LaunchAgents" "$target/LaunchAgents"
    cp -nvR "$source/Quicklook" "$target/Quicklook"
    cp -nvR "$source/bbedit_squirrel.plist" "$target/Application Support/BBEdit/Language Modules/Squirrel.plist"
    cp -nvR "$source/ffmpeg" "$target/ffmpeg"

    cp -nv "$source/HomebrewMe.terminal" "$HOME/Desktop/HomebrewMe.terminal"
    echo "Terminal settings file 'HomebrewMe' copied to desktop. To use it, open Terminal > Preferences > Profiles and import"

    cp -nv "$source/pixelmator_shapes.pxs" "$HOME/Desktop/pixelmator_shapes.pxs"
    echo "Pixelmater shapes file 'pixelmator_shapes.pxs' copied to desktop. To use it, open Pixelmator > File > Import..."
fi

echo Done
