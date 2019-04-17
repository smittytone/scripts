#!/bin/bash

# Update the apt-get database, etc.
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get autoremove -y

# Remove stock folders
rm -r Pictures
rm -r Music
rm -r Videos
rm -r python_games
rm -r Templates
rm -r MagPi

# Update .bashrc
echo "export PS1='\u@\h:\w > '" >> .bashrc
echo "alias la='ls -lah --color=auto'" > .bash_aliases
echo "alias ls='ls -l --color=auto'" >> .bash_aliases
echo "alias rs='sudo shutdown -r now'" >> .bash_aliases
echo "alias sd='sudo shutdown -h now'" >> .bash_aliases
echo "alias update='sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y'" >> .bash_aliases

# Wifi setup
read -p "Enter your WiFi SSID"
if [ -z "$REPLY" ]; then
    echo "Not a vaild SSID -- cancelling..."
    exit 1
fi
ssid=$REPLY

read -s -p "Enter your WiFi password (just hit [ENTER] for no password)"
if [ -z "$REPLY" ]; then
    read -n 1 -s -p "You have entered no password -- is that correct?"
    exit 1
fi
pwd=$REPLY

sudo echo "network={ ssid='boobaahoobaa' psk='stanth0rpe$' }" >> /etc/wpa_supplicant/wpa_supplicant.conf

# Set netdrive to autoload
mkdir /home/pi/netdrive
sudo mount -t cifs -o guest //192.168.0.3/Public /home/pi/netdrive
sudo echo "//192.168.0.3/Public /home/pi/netdrive cifs guest,noauto,x-systemd.automount 0 0" >> /etc/fstab

# Scrollphat install
curl -sSL get.pimoroni.com/scrollphat | bash

# Pyglow script install
curl get.pimoroni.com/piglow | bash

mkdir /home/pi/Pyglow
cp /home/pi/netdrive/Pi/Python/stats.py /home/pi/Pyglow/stats.py
chmod +x /home/pi/Pyglow/stats.py
sudo echo "python /home/pi/Pyglow/stays.py&" >> /etc/rc.local

# PiFace install
echo "Installing RTC"

wget https://raw.githubusercontent.com/piface/PiFace-Real-Time-Clock/master/install-piface-real-time-clock.sh
chmod +x install-piface-real-time-clock.sh
sudo ./install-piface-real-time-clock.sh
rm install-piface-real-time-clock.sh
echo "After restart, enter 'sudo date -s 23 OCT 2015 17:12:00' to set the clock"

