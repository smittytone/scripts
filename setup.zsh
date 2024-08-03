#!/bin/zsh

#
# setupmac.zsh
#
# Mac install script
#
# @author    Tony Smith
# @copyright 2024, Tony Smith
# @version   4.0.0
# @license   MIT
#


function show_errors() {
    if [[ ${#errors[@]} -ne 0 ]]; then
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
APP_VERSION=4.0.0
errors=()

# FROM 3.0.0 -- Get macOS verison
VERSION=$(system_profiler SPSoftwareDataType | grep macOS | awk {'print $4'})
VERSION_MAJOR=$(echo $VERSION | cut -d. -f1)
VERSION_MINOR=$(echo $VERSION | cut -d. -f2)
VERSION_PATCH=$(echo $VERSION | cut -d. -f3)

# FROM 3.0.0 -- Get the system architecture
ARCH=$(uname -a | awk -F" " '{print $NF}')

# Do intro
clear
echo "macOS Install Script ${APP_VERSION} on ${ARCH}"

read -k -s "key?Continue? [Y/N] "
[[ "${key:u}" != "Y" ]] && echo && exit 1
echo

: '
# Apply preferred Energy Saver settings
# NOTE Must be run as root
sudo pmset -b displaysleep 60
sudo pmset -a disksleep 60
sudo pmset -b sleep 60
sudo pmset -a womp 0
sudo pmset -b powernap 1

# Ask for and set the machines machine name
# NOTE Must be run as root
read "hostname?Enter your preferred hostname "
if [[ -n "${hostname}" ]]; then
    echo "Setting machine name to ${hostname}"
    sudo scutil --set HostName "${hostname}"
    sudo scutil --set LocalHostName "${hostname}"
    sudo scutil --set ComputerName "${hostname}"
    sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$hostname"
    dscacheutil -flushcache
fi

# Set dark mode
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'

# Clean up Home folder items
folders=(Movies Public)
echo -n "Hiding Home folder items: "
for folder in "${folders[@]}"; do
    chflags hidden "$HOME/${folder}"
    echo -n "${folder} "
done
echo

echo "Showing the Library folder..."
chflags nohidden "$HOME/Library"

# Homebrew
if [[ -n $(which brew) ]]; then
    echo "Installing Brew-sourced CLI tools... "
    brew update
    apps=(bash nano coreutils gitup jq ncurses readline shellcheck libdvdcss python3 hugo "sass/sass/sass" sphinx-doc "cloudflare/cloudflare/cloudflared")
    for app in "${apps[@]}"; do
        brew install "${app}"
    done

    echo "Installing Applications... "
    apps=(handbrake skype firefox omnidisksweeper)
    for app in "${apps[@]}"; do
        brew install --cask "${app}"
    done

    echo "Installing My Applications... "
    brew tap smittytone/homebrew-smittytone
    apps=(ascii mnu imageprep pdfmaker squinter the-valley utitool)
    for app in "${apps[@]}"; do
        brew install --cask "${app}"
    done
else
    errors+="Homebrew not installed"
    show_errors
fi

brew cleanup

# Node
echo "Installing node via nvm... "
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
#nvm install 20

# Cloudflared
echo "Installing cloudflared... "
target=/usr/local/etc/cloudflared
[[ ! -e "${target}" ]] && mkdir "${target}"
cat <<EOF > /usr/local/etc/cloudflared/config.yaml
proxy-dns: true
proxy-dns-upstream:
  - https://1.1.1.1/dns-query
  - https://8.8.8.8/dns-query
EOF
echo "To start cloudflare, run: sudo cloudflared service install"

# Set up git and clone key repos
echo "Preparing Git..."
target="$HOME/GitHub"
[[ ! -e "${target}" ]] && mkdir "${target}"
cd "${target}" || show_errors

if [[ -n $(which git) ]]; then
    repos=(scripts dotfiles devscripts)
    for repo in "${repos[@]}"; do
        [[ ! -e "${repo}" ]] && git clone "https://github.com/smittytone/${repo}.git"
    done
fi

# Run the app settings script
# FROM 3.0.0 -- a new script
# NOTE Script depends on dotfiles repo
target="$HOME/GitHub/scripts/configmac.zsh"
[[ -e "${target}" ]] && source "${target}"
'

# All done
read -k -s "key?Press [ENTER] to finish "
echo

# FROM 2.2.0
# Report any issues encountered
show_errors

# Successful completion
echo "Done"
exit 0
