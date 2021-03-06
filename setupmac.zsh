#!/bin/zsh

#
# setupmac.zsh
#
# Mac install script
#
# @author    Tony Smith
# @copyright 2020, Tony Smith
# @version   2.3.0
# @license   MIT
#


APP_NAME=$(basename $0)
APP_NAME=${APP_NAME:t}
APP_VERSION="2.3.0"
errors=()

# Do intro
clear
echo "macOS Install Script $APP_VERSION"

# REMOVED FROM 2.3.0 -- Update macOS
# sudo softwareupdate --install --all

# Install Xcode CLI
if xcode-select --install; then
    echo "Xcode CLI installed"
else
    echo "Xcode CLI already installed or could not be installed"
    errors+="Xcode CLI installation"
fi

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
read "hostname?Enter your preferred hostname "
if [[ -n "$hostname" ]]; then
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
target="$HOME/GitHub"
[[ ! -e "$target" ]] && mkdir "$target"

cd "$target" || exit 1
[[ ! -e scripts ]] && git clone https://github.com/smittytone/scripts.git
[[ ! -e doftiles ]] && git clone https://github.com/smittytone/dotfiles.git

# Run the app settings script
# FROM 1.0.5 correct called script's name
scripts/updatemac.zsh --full

# Restart Finder and Dock to effect changes
killall Finder Dock

# Install applications... brew first
echo "Installing Brew... "
if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"; then
    echo "Installing Brew-sourced Utilities... "
    apps=("bash" "nano" "coreutils" "gitup" "jq" "ncurses" "readline" "shellcheck" "libdvdcss" "node" "python3" "hugo")
    for app in "${apps[@]}"; do
        brew install "$app"
    done

    echo "Installing Applications... "
    apps=("handbrake" "vlc" "skype" "firefox" "omnidisksweeper")
    for app in "${apps[@]}"; do
        brew install --cask "$app"
    done

    # FROM 2.2.0
    echo "Installing My Applications... "
    brew tap smittytone/homebrew-smittytone
    apps=("mnu" "pdfmaker" "ascii" "the-valley")
    for app in "${apps[@]}"; do
        brew install --cask "$app"
    done
else
    echo "Could not install Brew"
    errors+="Brew installation"
fi

echo "Installing Cocoapods (requires authorizaton)... "
sudo gem install cocoapods

echo "Installing Pylint... "
pip3 install pylint

# FROM 2.1.0
# Install node packages
which npm >> /dev/null
if [[ $? -eq  0 ]]; then
    echo "Installing Node packages... "
    npm install -g uglify-js
    npm install -g uglifycss
fi

read -k -s "key?Press [ENTER] to open the App Store, or [S] to skip"
echo

# Make argument lowercase
key=${key:l}
[[ "$key" != "s" ]] && open '/Applications/App Store.app'

read -k -s "key?Press [ENTER] to open websites for other app downloads, or [S] to skip "
echo
key=${key:l}
if [[ "$key" != "s" ]]; then
    open http://www.dropbox.com
    open https://desktop.github.com
    open http://www.rogueamoeba.com/piezo
    open https://www.bresink.com/osx/TinkerTool/download.php
    open http://www.audacityteam.org/download/mac/
    open https://www.sketch.com
    #open http://www.skype.com
    #open http://handbrake.fr
    #open http://www.mozilla.org
    #open http://www.skype.com
    #open http://www.videolan.org
fi

read -k -s "key?Connect drive '500GB' and press [ENTER] to copy music, or [S] to skip "
echo
key=${key:l}
[[ "$key" != "s" ]] && cp -R /Volumes/500GB/Music/ "$HOME/Music"

read -k -s "Press [ENTER] to finish "
echo

echo "Cleaning up... "
brew cleanup

# FROM 2.2.0
# Report issues
if [[ ${#errors[@]} -eq 0 ]]; then
    echo "Errors during setup:"
    count=1
    for error in "${errors[@]}"; do
        echo "  ${count}. ${error}"
        (( count+=1 ))
    done
fi

echo "Done"
