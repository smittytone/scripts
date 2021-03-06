#!/bin/bash

# Pi Zero Installation Script 1.1.0

# Switch to home directory
cd "$HOME"

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
sudo apt-get update
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove

# Make directories
echo -e "\nCreating directories..."
mkdir "$HOME/GitHub"
mkdir "$HOME/Python"

# Update .bashrc
echo -e "\nConfiguring command line..."
echo "export PS1='\$(pwd) > '" >> .bashrc
echo "GIT=$HOME/GitHub" >> .bashrc
echo "alias la='ls -lahF --color=auto'" > .bash_aliases
echo "alias ls='ls -lhF --color=auto'" >> .bash_aliases
echo "alias rs='sudo shutdown -r now'" >> .bash_aliases
echo "alias sd='sudo shutdown -h now'" >> .bash_aliases
echo "alias python=python3" >> .bash_aliases
echo "alias update='sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y'" >> .bash_aliases
export PATH=$PATH:/usr/local/bin

# Applications
echo -e "\nInstalling screen..."
sudo apt-get -q -y install screen
echo " nginx..."
sudo apt-get -q -y install nginx
echo " ruby..."
sudo apt-get -q -y install ruby
echo " scrot..."
sudo apt-get -q -y install scrot
echo " mdless..."
sudo gem -q install mdless
echo -e "pylint\n"
sudo pip3 -q install pylint

# Node
version="12.4.0"
echo -e "\nInstalling Node..."
mkdir tmp
cd tmp || exit 1
wget "https://nodejs.org/dist/v$version/node-v$version-linux-armv6l.tar.gz"
tar -xzf "node-v$version-linux-armv6l.tar.gz"
cd "node-v$version-linux-armv6l"
sudo cp -R * /usr/local/

# Git
echo -e "\nCloning key repos..."
cd "$HOME/GitHub" || exit 1
git clone https://github.com/smittytone/dotfiles.git
git clone https://github.com/smittytone/scripts.git

# Setup configs
cp dotfiles/nanorc "$HOME"/.nanorc
cp dotfiles/pylintrc "$HOME"/.pylintrc
cp dotfiles/gitignore_global "$HOME"/.gitignore_global
git config --global core.excludesfile "$HOME"/.gitignore_global

echo -e "\nCleaning up..."
# Remove the script
cd "$HOME"
rm zinstall.sh
rm -r tmp

read -n 1 -s -p "Press any key to reboot (or [C] to cancel)" key
key=${key^^*}
if [ "$key" != "C" ]; then
    sudo shutdown -r now
else
    echo
fi
