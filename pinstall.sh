#!/bin/bash
# Pi Installation Script 1.3.0

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
rm -rf Bookshelf

# Update the apt-get database, etc.
echo "Updating system..."
sudo apt-get update
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove

# Make directories
echo "Creating directories..."
mkdir "$HOME/GitHub"

# Update .bashrc
echo "Configuring command line... "
echo $'export PS1=\'$PWD > \'' >> .bashrc
export PATH=$PATH:/usr/local/bin

# Applications
echo -n "Installing utilities: screen..."
sudo apt-get -q -y install screen
echo -n " scrot..."
sudo apt-get -q -y install scrot
echo -n " zsh..."
sudo apt-get -q -y install zsh
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
if cd "$HOME/GitHub"; then
    echo "Cloning key repos..."
    git clone https://github.com/smittytone/dotfiles.git
    git clone https://github.com/smittytone/scripts.git

    # Setup configs
    cp dotfiles/Pi/bash_aliases "$HOME"/.bash_aliases
    cp dotfiles/Pi/nanorc "$HOME"/.nanorc
    cp dotfiles/Universal/pylintrc "$HOME"/.pylintrc
    cp dotfiles/Universal/gitignore_global "$HOME"/.gitignore_global
    git config --global core.excludesfile "$HOME"/.gitignore_global

    # From 1.1.0
    # Setup and enable VNC service
    sudo cp dotfiles/Pi/pi_virtual_desktop.service /etc/systemd/system/vnc_vd.service
    sudo systemctl enable vnc_vd.service
fi

# FROM 1.3.0 set Z as default shell
z_path=$(which zsh)
if [[ -f "${z_path}" ]]; then
    chsh -s "${z_path}"
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
