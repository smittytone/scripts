#!/usr/bin/env bash

# Mac install script
# Version 1.1.0

# Do intro
clear
echo "macOS Install Script 1.1.0"

# Set exit-on-failure
set -e

# Update macOS
sudo softwareupdate --install --all

# Apply preferred Energy Saver settings
sudo pmset -a lessbright 0
sudo pmset -a disksleep 10
sudo pmset -b displaysleep 15
sudo pmset -b sleep 15
sudo pmset -b powernap 0
sudo pmset -c displaysleep 60
sudo pmset -c sleep 60
sudo pmset -c powernap 1

# Ask for and set the machine's machine name
read -p "Enter your preferred hostname " hostname
if [ -n "$hostname" ]; then
    echo -e "\nSetting machine name to $hostname"
    sudo scutil --set HostName "$hostname"
    sudo scutil --set LocalHostName "$hostname"
    sudo scutil --set ComputerName "$hostname"
    sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$hostname"
    dscacheutil -flushcache
fi

# Set dark mode
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'

# Clean up Home folder items
echo -n "Hiding Home folder items: "
chflags hidden "$HOME/Movies"
echo -n "Movies, "
chflags hidden "$HOME/Public"
echo "Public"
echo "Showing the Library folder..."
chflags nohidden "$HOME/Library"

# Set up git and clone key repos
echo "Preparing Git..."
xcode-select --install
target="$HOME/GitHub"
if ! [ -e "$target" ]; then
    mkdir "$target"
fi

cd "$target" || exit 1
git clone https://github.com/smittytone/scripts.git
git clone https://github.com/smittytone/dotfiles.git

# Run the app settings script
# FROM 1.0.5 correct called script's name
"$target/scripts/updatemac.sh --full"

# Restart Finder and Dock to effect changes
killall Finder Dock

# Install applications... brew first
echo "Installing Brew... "
if /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"; then
    echo "Installing Brew-sourced Utilities... "
    apps=("bash" "nano" "coreutils" "gitup" "jq" "ncurses" "readline" "shellcheck" "libdvdcss" "node" "python3" "hugo")
    for app in "${apps[@]}"; do
        brew install "$app"
    done

    echo "Installing Applications... "
    apps=("handbrake" "vlc" "skype" "firefox" "omnidisksweeper")
    for app in "${apps[@]}"; do
        brew cask install "$app"
    done
fi

echo "Installing Cocoapods (requires authorizaton)... "
sudo gem install cocoapods

echo "Installing Pylint... "
pip3 install pylint

read -n 1 -s -p "Press [ENTER] to open websites for other app downloads, or [S] to skip " key
echo
# Make argument lowercase
key=${key,,}
if [ "$key" != "s" ]; then
    open http://www.dropbox.com
    open http://www.barebones.com
    open https://desktop.github.com
    open http://www.rogueamoeba.com/piezo
    open https://www.bresink.com/osx/TinkerTool/download.php
    open http://www.audacityteam.org/download/mac/
    #open http://www.skype.com
    #open http://handbrake.fr
    #open http://www.mozilla.org
    #open http://www.skype.com
    #open http://www.videolan.org
fi

read -n 1 -s -p "Press [ENTER] to open the App Store, or [S] to skip " key
echo
key=${key,,}
if [ "$key" != "s" ]; then
    open "/Applications/App Store.app"
fi

read -n 1 -s -p "Connect drive '2TB-APFS' and press [ENTER] to copy music, or [S] to skip " key
echo
key=${key,,}
if [ "$key" != "s" ]; then
    cp -R /Volumes/2TB-APFS/Music "$HOME/Music"
fi

read -n 1 -s -p "Press [ENTER] to finish "
echo

echo "Cleaning up... "
brew cleanup

echo "Done"
