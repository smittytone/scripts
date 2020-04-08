#!/bin/bash
# Pi Installation Script 1.1.1

# Switch to home directory
cd "$HOME" || exit 1

# Remove stock folders
echo "Removing home sub-directories..."
rm -rf Pictures
rm -rf Music
rm -rf Videos
rm -rf python_games
rm -rf Templates
rm -rf MagPi

# Update the apt-get database, etc.
echo "Updating system..."
sudo apt-get update
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove

# Make directories
echo "Creating directories..."
mkdir "$HOME/Documents/GitHub"
mkdir "$HOME/Python"

# Update .bashrc
echo "Configuring command line... "
echo $'export PS1=\'$PWD > \'' >> .bashrc
export PATH=$PATH:/usr/local/bin
#echo "alias la='ls -lah --color=auto'" > .bash_aliases
#echo "alias ls='ls -l --color=auto'" >> .bash_aliases
#echo "alias rs='sudo shutdown -r now'" >> .bash_aliases
#echo "alias sd='sudo shutdown -h now'" >> .bash_aliases
#echo "alias update='sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y'" >> .bash_aliases

# Applications
echo -n "Installing utilities: screen..."
sudo apt-get -q -y install screen
echo -n " nginx..."
sudo apt-get -q -y install nginx
echo -n " ruby..."
sudo apt-get -q -y install ruby
echo -n " scrot..."
sudo apt-get -q -y install scrot
echo -n " mdless..."
sudo gem install -q --silent mdless
echo -n " pylint"
sudo pip3 -q install pylint

# Node
# version="12.4.0"
# echo -e "\nInstalling Node $version..."
# mkdir tmp
# cd tmp || exit 1
# wget "https://nodejs.org/dist/v$version/node-v$version-linux-arm64.tar.gz"
# tar -xzf "node-v$version-linux-arm64.tar.gz"
# cd "node-v$version-linux-arm64"
# sudo cp -R * /usr/local/

# Git
if cd "$HOME/Documents/GitHub"; then
    echo "Cloning key repos..."
    git clone https://github.com/smittytone/dotfiles.git
    git clone https://github.com/smittytone/scripts.git

    # Setup configs
    cp dotfiles/pi_bash_aliases "$HOME"/.bash_aliases
    cp dotfiles/nanorc "$HOME"/.nanorc
    cp dotfiles/pylintrc "$HOME"/.pylintrc
    cp dotfiles/gitignore_global "$HOME"/.gitignore_global
    git config --global core.excludesfile "$HOME"/.gitignore_global

    # From 1.1.0
    # Setup and enable VNC service
    sudo cp dotfiles/pi_virtual_desktop.service /etc/systemd/system/vnc_vd.service
    sudo systemctl enable vnc_vd.service
fi

# Remove the script
if cd "$HOME"; then
    echo "Cleaning up..."
    rm pinstall.sh
    rm -rf tmp
fi

read -n 1 -s -p "Press [S] to shutdown, [R] to reboot or any other key to cancel " key
key=${key^^*}
if [ "$key" = "S" ]; then
    sudo shutdown -h now
elif [ "$key" = "R" ]; then
    sudo shutdown -r now
else
    echo
fi
