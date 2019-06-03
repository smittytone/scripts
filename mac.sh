#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash

# Mac install script
# Version 1.0.1

# Do intro
clear
echo "macOS Install Script 1.0.1"

# Get server access
read -p "Please enter your server username: "
echo
if [ -z "$REPLY" ]; then
    echo "Not a vaild username -- cancelling..."
    exit 1
else
    user=$REPLY
fi

read -p "Please enter your server password: "
echo
if [ -z "$REPLY" ]; then
    echo "Not a vaild password -- cancelling..."
    exit 1
else
    pass=$REPLY
fi

credo="$user:$pass"
if ! [ -e mntpoint ]; then
    mkdir mntpoint
fi

if mount -v -t smbfs "//$credo@192.168.0.3/homes/macsource" mntpoint; then
    # The mount operation worked, so copy over key files
    echo "Copying fonts from server..."
    cp -nvR mntpoint/fonts "$HOME/$target/Fonts"
    echo "Copying xroar ROMs from server..."
    cp -nvR mntpoint/xroar "$HOME/$target/xroar"

    # Copy these dylibs then make the required aliases
    cp -va mntpoint/ffmpeg "$HOME/Library/ffmpeg-mac-2.2.2"
    for file in "$HOME"/Library/ffmpeg-mac-2.2.2; do
        if [ -f "$file" ]; then
            extension=${file##*.}
            extension=${extension^^*}

            if [ "$extension" != "TXT" ]; then
                linkname="${file//[0-9]/}"
                linkname="${linkname//../.}"
                ln -s "$file" "$linkname"
            fi
        fi
    done
else
    echo "Unable to copy files from server (return code: $?)"
fi

echo -n "Hiding Home folder items: "
chflags hidden "$HOME"/Movies
echo -n "Movies, "
chflags hidden "$HOME"/Public
echo "Public"

echo "Showing the Home Library folder..."
chflags nohidden "$HOME"/Library

echo "Preparing Git..."
target="$HOME/Documents/GitHub"
if ! [ -d "$target" ]; then
    mdkir "$target"
fi

cd "$target" || exit 1
git clone https://github.com/smittytone/scripts.git
git clone https://github.com/smittytone/dotfiles.git

source="$target/dotfiles"
echo "Updating primary config files... "
cp -v "$source/nanorc" "$HOME/.nanorc"
cp -v "$source/bash_profile" "$HOME/.bash_profile"

if ! [ -e "$HOME"/.config ]; then
    echo "Adding ~/.config... "
    mkdir "$HOME"/.config
fi

if ! [ -e "$HOME"/.config/gitup ]; then
    echo "Adding ~/.config/gitup... "
    mkdir "$HOME"/.config/gitup
fi

cp -v "$source/bookmarks" "$HOME/.config/gitup/bookmarks"
cp -v "$source/vs_settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
cp -vR "$source/Services/Copy File Path.workflow" "$HOME/Library/Services/Copy File Path.workflow"
cp -vR "$source/LaunchAgents" "$HOME/Library/LaunchAgents"
cp -vR "$source/Quicklook" "$HOME/Library/Quicklook"
cp -vR "$source/ffmpeg" "$target/ffmpeg"

echo "Adding ~/.config/git... "
if ! [ -e "$HOME"/.config/git ]; then
    mkdir ~/.config/git
fi

if cp -nv "$source"/gitignore_global "$HOME"/.config/git/gitignore_global; then
    # Add a reference to the file to git (assumes git installed)
    git config --global core.excludesfile "$HOME"/.config/git/gitignore_global
fi

cp -nv "$source/HomebrewMe.terminal" "$HOME/Desktop/HomebrewMe.terminal"
echo "Terminal settings file 'HomebrewMe' copied to desktop. To use it, open Terminal > Preferences > Profiles and import "

cp -nv "$source/pixelmator_shapes.pxs" "$HOME/Desktop/pixelmator_shapes.pxs"
echo "Pixelmater shapes file 'pixelmator_shapes.pxs' copied to desktop. To use it, open Pixelmator > File > Import..."

echo "Installing Brew... "
if /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"; then
    echo "Brew installed -- installing Brew-sourced Applications..."
    brew install bash
    brew install coreutils
    brew install gitup
    brew install jq
    brew install ncurses
    brew install readline
    brew install shellcheck
    brew install gitup
    brew install libdvdcss
fi

echo "Installing Cocoapods (requires authorizaton)... "
sudo gem install cocoapods

echo "Installing Pylint... "
pip3 install pylint

echo "Installing apps... "
brew cask install handbrake
brew cask install vlc
brew cask install skype
brew cask install firefox
brew cask install omnidisksweeper

read -n 1 -s -p "Press [ENTER] to open websites for app downloads, or [S] to skip " key
echo
key=${key^^*}
if [ "$key" != "S" ]; then
    open http://www.dropbox.com
    open http://www.barebones.com
    open https://desktop.github.com
    #open http://www.mozilla.org
    open http://www.rogueamoeba.com/piezo
    #open http://www.skype.com
    #open http://handbrake.fr
    open https://www.bresink.com/osx/0TinkerTool/download.php
    open http://www.audacityteam.org/download/mac/
    #open http://www.skype.com
    #open http://www.videolan.org
fi

read -n 1 -s -p "Press [ENTER] to open the App Store, or [S] to skip " key
echo
key=${key^^*}
if [ "$key" != "S" ]; then
    open "/Applications/App Store.app"
fi

read -n 1 -s -p "Connect drive '2TB-APFS' and press [ENTER] to copy music, or [S] to skip " key
echo
key=${key^^*}
if [ "$key" != "S" ]; then
    cp -R /Volumes/2TB-APFS/Music "$HOME/Music"
fi

read -n 1 -s -p "Press [ENTER] to finish "
echo

echo "Cleaning up... "
# Unmount the share; keep the operation success value for each
# Make sure the unmount operations succeeded, warning if not
if umount mntpoint; then
    # Remove the share mount points if both unmounts were successful
    rm mntpoint
else
    echo "$(pwd)/mntpoint failed to unmount -- please unmount it manually and remove the mointpoint "
fi

echo "Done"