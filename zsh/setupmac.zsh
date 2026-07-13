#!/bin/zsh

#
# setupmac.zsh
#
# Mac install script
#
# @author    Tony Smith
# @copyright 2020, Tony Smith
# @version   3.0.1
# @license   MIT
#


function show_errors() {
    if [[ ${#errors[@]} -eq 0 ]]; then
        echo "Errors encountered during setup:"
        count=1
        for error in "${errors[@]}"; do
            echo "  ${count}. ${error}"
            (( count+=1 ))
        done
        exit 1
    fi
}


APP_NAME=$(basename $0)
APP_NAME=${APP_NAME:t}
APP_VERSION="3.0.1"
errors=()

# Do intro
clear
echo "macOS Install Script $APP_VERSION"

# REMOVED FROM 2.3.0 -- Update macOS
# sudo softwareupdate --install --all

# FROM 3.0.0 -- Get macOS verison
VERSION=$(system_profiler SPSoftwareDataType | grep macOS | awk {'print $4'})
VERSION_MAJOR=$(echo $VERSION | cut -d. -f1)
VERSION_MINOR=$(echo $VERSION | cut -d. -f2)
VERSION_PATCH=$(echo $VERSION | cut -d. -f3)

# FROM 3.0.0 -- Get the system architecture
ARCH=$(uname -a | awk -F" " '{print $NF}')

# Apply preferred Energy Saver settings
# NOTE Must be run as root
sudo pmset -a lessbright 0
sudo pmset -a disksleep 10
sudo pmset -a womp 0
sudo pmset -b displaysleep 15
sudo pmset -b sleep 15
sudo pmset -b powernap 0
sudo pmset -c displaysleep 60
sudo pmset -c sleep 60
sudo pmset -c powernap 1

# Ask for and set the machine's machine name
# NOTE Must be run as root
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

# Install Xcode CLI
#if xcode-select --install; then
#    echo "Xcode CLI installed"
#els
#    echo "Xcode CLI already installed or could not be installed"
#    errors+="Xcode CLI installation"
#fi

# Install applications... brew first
# NOTE This will install Xcode CLI
echo "Installing Brew... "
if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"; then
    echo "Installing Brew-sourced Utilities... "
    apps=(bash nano coreutils gitup jq ncurses readline shellcheck libdvdcss node python3 hugo "sass/sass/sass" sphinx-doc)
    for app in "${apps[@]}"; do
        brew install "${app}"
    done

    echo "Installing Applications... "
    apps=(handbrake skype firefox omnidisksweeper)
    for app in "${apps[@]}"; do
        brew install --cask "${app}"
    done

    # FROM 2.2.0
    echo "Installing My Applications... "
    brew tap smittytone/homebrew-smittytone
    apps=(ascii mnu imageprep pdfmaker squinter the-valley utitool)
    for app in "${apps[@]}"; do
        brew install --cask "${app}"
    done

    # FROM 3.0.0
    brew link --force sphinx-doc
else
    echo "Could not install Brew"
    errors+="Brew installation"
    show_errors
fi

# Set up git and clone key repos
echo "Preparing Git..."
target="$HOME/GitHub"
[[ ! -e "${target}" ]] && mkdir "${target}"

cd "${target}" || show_errors
[[ ! -e scripts ]] && git clone https://github.com/smittytone/scripts.git
[[ ! -e dotfiles ]] && git clone https://github.com/smittytone/dotfiles.git

# Run the app settings script
# FROM 3.0.0 -- a new script
# NOTE Script depends on dotfiles repo
scripts/configmac.zsh

#echo "Installing Cocoapods (requires authorizaton)... "
#sudo gem install cocoapods

#echo "Installing Python modules... "
#pip3 install pylint sphinx-rtd-theme

# FROM 2.1.0
# Install node packages
which npm >> /dev/null
if [[ $? -eq  0 ]]; then
    echo "Installing Node packages... "
    npm install -g uglify-js
    npm install -g uglifycss
fi

# All done
read -k -s "key?Press [ENTER] to finish "
echo

echo "Cleaning up... "
brew cleanup

# FROM 2.2.0
# Report any issues encountered
show_errors

echo "Done"
exit 0
