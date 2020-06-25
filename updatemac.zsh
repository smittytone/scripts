#!/bin/zsh

#
# updatemac.zsh
#
# Update local Macs user config files
# (eg. between multiple machines)
#
# @author    Tony Smith
# @copyright 2019-20, Tony Smith
# @version   4.1.0
# @license   MIT
#


# Set up key directories
file_source="$HOME/GitHub/dotfiles"
file_target="$HOME/Library"

if [[ ! -e "$file_source" ]]; then
    echo "Please clone the repo \'dotfiles\' before proceeding -- exiting "
    exit 1
fi

# Process any arguments
# NOTE P == Partial, ie. only update frequently used app configs
#      F == Full, ie. update frequently used app configs AND apply
#           macOS configurations AND occasional use app configs
choice="ASK"
for arg in $@; do
    # Make the argument upper case for comparisons
    theArg=${arg:u}
    if [[ "$theArg" = "-F" || "$theArg" = "--FULL" ]]; then
        choice="F"
    elif [[ "$theArg" = "-P" || "$theArg" = "--PARTIAL" ]]; then
        choice="P"
    fi
done

# No valid arguments passed, so ask the user for the type of update
if [[ "$choice" = "ASK" ]]; then
    # Get input, zsh style
    read -k -s "choice?Full [F] or partial [P] update? "
    echo
    if [[ $choice = $'\n' ]]; then
        echo "Cancelling..."
        exit 0
    fi
fi

choice=${choice:u}
if [[ "$choice" != "F" && "$choice" != "P" ]]; then
    echo "Invalid option selected: '$choice' -- cancelling... "
    exit 1
fi

# The following are items that are likely to change often
echo "Updating primary config files... "

# bash profile
# FROM 2.0.1 rename saved file
cp -v "$file_source/Mac/bash_profile" "$HOME/.bash_profile"

# FROM 2.0.1
# ZSH rc file
cp -v "$file_source/Mac/zshrc" "$HOME/.zshrc"

# nano rc file
cp -v "$file_source/Mac/nanorc" "$HOME/.nanorc"

# vscode settings
cp -v "$file_source/Mac/vs_settings.json" "$file_target/Application Support/Code/User/settings.json"

# FROM 4.0.0
# pylint rc file
cp -v "$file_source/Universal/pylintrc" "$HOME/.pylintrc"

# gitup config
# FROM 3.0.1 only copy on a full install or if file doesn't exist
if [[ ! -e "$HOME/.config/gitup" ]]; then
    echo "Adding ~/.config/gitup... "
    mkdir -p "$HOME/.config/gitup" || echo 'Could not add ~/.config/gitup'
    cp -v "$file_source/Mac/bookmarks" "$HOME/.config/gitup/bookmarks"
else
    if [[ "$choice" = "F" || ! -e "$HOME/.config/gitup/bookmarks" ]]; then
        cp -v "$file_source/Mac/bookmarks" "$HOME/.config/gitup/bookmarks"
    fi
fi

# git config
if [[ ! -e "$HOME/.config/git" ]]; then
    echo "Adding ~/.config/git... "
    mkdir -p "$HOME/.config/git" || echo 'Could not add ~/.config/git'
fi

#FROM 4.§.0
# binstall
bin_dir=$HOME/bin
scripts_dir=$GIT/scripts
if [[ ! -e $bin_dir ]]; then
    mkdir -p $bin_dir || echo 'Could not create ~/bin'
fi
if [[ -e $scripts_dir/binstall.zsh ]]; then
    cp $scripts_dir/binstall.zsh $bin_dir/binstall
    chmod +v $bin_dir/binstall
    $bin_dir/binstall
fi

# git global exclude file
# Added it to partial install in 1.0.3
if cp -v "$file_source/Universal/gitignore_global" "$HOME/.config/git/gitignore_global"; then
    # Add a reference to the file to git (assumes git installed)
    git config --global core.excludesfile "$HOME/.config/git/gitignore_global"
fi

# The following are items that won't be overwritten. They are very, very unlikely
# to be changed once installed in the first place
if [[ "$choice" = "F" ]]; then
    echo "Updating additional config files... "
    cp -nvR "$file_source/Mac/Services/" "$file_target/Services"
    cp -nvR "$file_source/Mac/Quicklook/" "$file_target/Quicklook"

    # FROM 1.5.0 -- Add 64-bit libdvdcss
    cp -nv "$file_source/Mac/libdvdcss/libdvdcss.2.dylib" /usr/local/lib/libdvdcss.2.dylib

    # FROM 1.4.0 -- Add second terminal file (HomebrewMeDark)
    cp -nv "$file_source/Mac/HomebrewMe.terminal" "$HOME/Desktop/HomebrewMe.terminal"
    cp -nv "$file_source/Mac/HomebrewMeDark.terminal" "$HOME/Desktop/HomebrewMeDark.terminal"
    echo "Terminal settings files 'HomebrewMe' and 'HomebrewMeDark' copied to desktop. To use them, open Terminal > Preferences > Profiles and import"

    cp -nv "$file_source/Mac/pixelmator_shapes.pxs" "$HOME/Desktop/pixelmator_shapes.pxs"
    echo "Pixelmater shapes file 'pixelmator_shapes.pxs' copied to desktop. To use it, open Pixelmator > File > Import..."

    # FROM 2.0.0
    # Install Xcode CLI if necessary
    result=$(xcode-select --install 2>&1)
    error=$(grep 'already installed' < <(echo -e "$result"))
    if [[ -n "$error" ]]; then
        # CLI installed already
        echo "Xcode Command Line Tools installed"
    else
        # Check for opening of external installer
        note=$(grep 'install requested' < <(echo -e "$result"))
        if [[ -n "$note" ]]; then
            echo "Installing Xcode Command Line Tools... "
        fi
    fi

    # FROM 1.1.0
    # Run the various macOS config scriptlets
    echo "Configuring macOS... "
    if cd "$file_source/Mac/config"; then
        echo *
        for task in *; do
            echo $task
            ./$task
        done
    fi
fi

echo "Mac configuration files updated"
