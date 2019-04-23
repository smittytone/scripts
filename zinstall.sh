#!/bin/bash

# Pi Zero Installation Script 1.0.0

# Switch to home directory
cd /home/pi

# Remove stock folders
echo "Removing home sub-directories..."
rm -rf Pictures
rm -rf Music
rm -rf Videos
rm -rf python_games
rm -rf Templates
rm -rf MagPi

# Updating System
echo -e "\nUpdating system..."
sudo apt-get update -y
sudo apt-get dist-upgrade -y
sudo apt-get autoremove

# Make directories
echo -e "\nCreating directories..."
mkdir Documents/GitHub
mkdir Python

# Update .bashrc
echo -e "\nConfiguring command line..."
echo "export PS1='$PWD > '" >> .bashrc
echo "alias la='ls -lahF --color=auto'" > .bash_aliases
echo "alias ls='ls -lhF --color=auto'" >> .bash_aliases
echo "alias rs='sudo shutdown -r now'" >> .bash_aliases
echo "alias sd='sudo shutdown -h now'" >> .bash_aliases
echo "alias python=python3" >> .bash_aliases
echo "alias update='sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y'" >> .bash_aliases
export PATH=$PATH:/usr/local/bin

# Wifi setup

read -p "Enter your WiFi SSID: "
if [ -z "$REPLY" ]; then
    echo "Not a vaild SSID -- cancelling..."
    exit 1
fi
ssid=$REPLY

read -s -p "Enter your WiFi password (just hit [ENTER] for no password): "
if [ -z "$REPLY" ]; then
    read -n 1 -s -p "You have entered no password -- is that correct?"
    exit 1
fi
psk=$REPLY

sudo echo "network={ ssid=$ssid psk=$psk }" >> /etc/wpa_supplicant/wpa_supplicant.conf

# Applications
echo -e "\nAdding utilities..."
sudo apt-get install -y screen nginx ruby scrot
sudo gem install mdless

# Node
version="10.13.0"
echo -e "\nInstalling Node..."
mdkir tmp
cd tmp
wget "https://nodejs.org/dist/v$version/node-v$version-linux-armv6l.tar.gz"
tar -xzf "node-v$version-linux-armv6l.tar.gz"
cd "node-v$version-linux-armv6l"
sudo cp -R * /usr/local/
cd ~
rm -r tmp