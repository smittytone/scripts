#!/bin/zsh

# DEPENDENCIES
# dofiles repo at $HOME/GitHub/dotfiles

# Set up key directories
file_source="$HOME/GitHub/dotfiles"
file_target="$HOME/Library"

if [[ -e "${file_source}" ]]; then
    # The following are items that are likely to change often
    echo "Updating primary config files... "

    # bash profile
    cp -v "${file_source}/Mac/bash_profile" "$HOME/.bash_profile"

    # ZSH rc file
    cp -v "${file_source}/Mac/zshrc_base" "$HOME/.zshrc"
    echo "export PICO_SDK_PATH=$HOME/GitHub/pico-sdk" > "$HOME/.exports"

    # nano rc file
    cp -v "${file_source}/Mac/nanorc" "$HOME/.nanorc"

    # vscode settings
    cp -v "${file_source}/Mac/vs_settings.json" "${file_target}/Application Support/Code/User/settings.json"

    # pylint rc file
    cp -v "${file_source}/Universal/pylintrc" "$HOME/.pylintrc"

    # git config
    if [[ ! -e "$HOME/.config/git" ]]; then
        echo "Adding ~/.config/git... "
        mkdir -p "$HOME/.config/git" || echo 'Could not add ~/.config/git'
    fi

    # git global exclude file
    # Added it to partial install in 1.0.3
    if cp -v "${file_source}/Universal/gitignore_global" "$HOME/.config/git/gitignore_global"; then
        # Add a reference to the file to git (assumes git installed)
        git config --global core.excludesfile "$HOME/.config/git/gitignore_global"
    fi

    echo "Updating additional config files... "
    cp -nvR "${file_source}/Mac/Services/" "${file_target}/Services"

    cp -nv "${file_source}/Mac/HomebrewMe.terminal" "$HOME/Desktop/HomebrewMe.terminal"
    cp -nv "${file_source}/Mac/HomebrewMeDark.terminal" "$HOME/Desktop/HomebrewMeDark.terminal"
    echo "Terminal settings files 'HomebrewMe' and 'HomebrewMeDark' copied to desktop. To use them, open Terminal > Preferences > Profiles and import"

    # Run the various macOS config scriptlets
    echo "Configuring macOS... "
    if cd "${file_source}/Mac/config"; then
        chmod +x ./*
        for task in *; do
            #echo ${task}
            source ${task}
        done
    fi

    echo "Mac configuration files updated"

    # Restart Finder and Dock to effect changes
    killall Finder Dock
else
    echo "No dotfiles repo cloned
fi