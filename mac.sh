#!/bin/bash

# Mac install script
# Version 1.0.3

# Do intro
clear
echo "macOS Install Script 1.0.3"

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
echo -e "\nSetting machine name to $hostname"
if [ -n "$hostname" ]; then
    sudo scutil --set HostName "$hostname"
    sudo scutil --set LocalHostName "$hostname"
    sudo scutil --set ComputerName "$hostname"
    sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$hostname"
    dscacheutil -flushcache
fi

# Run the various mac config scriptlets
cd "$target/scripts/config"
for task in *; do
    . "$task"
done

# Restart Finder and Dock to effect changes
killall Finder Dock

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
target="$HOME/Documents/GitHub"
if ! [ -e "$target" ]; then
    mdkir "$target"
fi

cd "$target" || exit 1
git clone https://github.com/smittytone/scripts.git
git clone https://github.com/smittytone/dotfiles.git

# Run the app settings script
"$target/scripts/upconf.sh --full"

# Install applications... brew first
echo "Installing Brew... "
if /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"; then
    echo "Installing Brew-sourced Utilities... "
    apps=("bash" "nano" "coreutils" "gitup" "jq" "ncurses" "readline" "shellcheck" "gitup" "libdvdcss" "node" "python3")
    for app in "${apps[@]}"; do
        brew install "$app"
    done

    echo "Installing Applications... "
    apps=("handbrake" "vlc" "skype" "firefox" "omnidisksweeper" "google-chrome" "zoomus" "qlmarkdown")
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
key=${key^^*}
if [ "$key" != "S" ]; then
    open http://www.dropbox.com
    open http://www.barebones.com
    open https://desktop.github.com
    open http://www.rogueamoeba.com/piezo
    open https://www.bresink.com/osx/0TinkerTool/download.php
    open http://www.audacityteam.org/download/mac/
    #open http://www.skype.com
    #open http://handbrake.fr
    #open http://www.mozilla.org
    #open http://www.skype.com
    #open http://www.videolan.org
fi

read -n 1 -s -p "Press [ENTER] to open the App Store, or [S] to skip " key
echo
key=${key^^*}
if [ "$key" != "S" ]; then
    open "/Applications/App Store.app"
fi

# Get server access for remaining items
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

    # Unmount the share
    if umount mntpoint; then
        # Remove the share mount points if the unmount was successful
        rm mntpoint
    else
        echo "$(pwd)/mntpoint failed to unmount -- please unmount it manually and remove the mointpoint "
    fi
else
    echo "Unable to copy files from server (return code: $?)"
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
brew cleanup

echo "Done"