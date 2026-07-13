#!/bin/bash

#
# updatepi.sh
#
# Update local Pi user config files
# (eg. between multiple machines)
#
# @author    Tony Smith
# @copyright 2019-23, Tony Smith
# @version   4.0.0
# @license   MIT
#

show_error_and_exit() {
    echo $1
    exit 1
}

if [[ "$EUID" -ne 0 ]]; then
    show_error_and_exit "Please run this script as root"
fi

if [[ ${1} == "" ]]; then
    show_error_and_exit 'Usage: sudo ./updatepi.sh {username}'
fi

id "${1}" > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    show_error_and_exit "User '${1}' not known"
fi

file_source="$HOME/GitHub/dotfiles"

apt update
apt install -y zsh git curl > /dev/null 2>&1

sudo -u ${1} mdkir -p "$HOME/GitHub"
sudo -u ${1} cd "$HOME/GitHub"
sudo -u ${1} git clone https://github.com/smittytone/dotfiles

if [[ ! -e "${file_source}" ]]; then
    show_error_and_exit "Please clone the repo 'dotfiles' before proceeding -- exiting "
fi

echo "Updating primary config files... "

# nano rc file
cp -v "$file_source/Pi/nanorc" "$HOME/.nanorc"

# bash profile
cp -v "$file_source/Pi/bash_aliases" "$HOME/.bash_aliases"

# Sync .zshrc
cp -v "$file_source/Pi/zshrc" "$HOME/.zshrc"

# pylint rc file
cp -v "$file_source/Universal/pylintrc" "$HOME/.pylintrc"

# git config
if [[ ! -e "$HOME/.config/git" ]]; then
    echo "Adding ~/.config/git... "
    mkdir -p "$HOME/.config/git"
fi

# git global exclude file
if cp -v "$file_source/Universal/gitignore_global" "$HOME/.config/git/gitignore_global"; then
    # Add a reference to the file to git
    git config --global core.excludesfile "$HOME/.config/git/gitignore_global"
fi

# Change shell
chsh -s /bin/zsh ${1}

# Install node
curl -sL https://deb.nodesource.com/setup_19.x | bash
apt install -y nodejs

echo "Pi configuration files updated -- please reboot"
