#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash

# Pi Image Installation
# Version 1.0.0

url=https://downloads.raspberrypi.org/raspbian_latest

clear
read -n 1 -s -p "Install Pi 3 [3] or Zero [Z] " choice
echo

choice=${choice,,}

if [[ "$choice" != "3" && "$choice" != "z" ]]; then
    exit 0
fi

pitype=Zero
if [ "$choice" = "3" ]; then
    pitype=3
fi

if ! [ -e "tmp" ]; then
    mkdir tmp
    cd tmp || exit 1

    if ! [ -e "tmp/p.img" ]; then
        echo "Downloading Raspberry Pi $pitype OS image... "
        curl -O -L -# "$url"
    fi

    echo "Decompressing Raspberry Pi $pitype OS image... "
    mv raspbian_latest r.zip
    unzip r.zip
    mv *.img p.img
else
    cd tmp || exit 1
fi

read -n 1 -s -p "Insert SD card and press any key when it has appeared on the desktop "
echo

ok=0
while [ $ok -eq 0 ] ; do
    echo "Disk list... "
    diskutil list

    read -p "Enter the SD card's disk number (eg. 2 for /dev/disk2) " disknum

    if [ -z "$disknum" ]; then
        echo "Invalid disk number -- exiting "
        exit 1
    fi

    unmountname="/dev/disk$disknum"
    copyname="/dev/rdisk$disknum"

    if diskutil unmountdisk "$unmountname"; then

        if [ -e "p.img" ]; then
            echo "About to copy Raspberry Pi $pitype OS image to SD card $unmountname... "

            read -n 1 -s -p "Are you sure? [Y/N] " key
            if [ ${key^^*} != "Y" ]; then
                echo
                continue
            fi

            echo "Copying Raspberry Pi $pitype OS image to SD card $unmountname... "
            sudo dd if=p.img of="$copyname" bs=1m
        fi

        read -n 1 -s -p "Press any key when 'boot' has appeared on the desktop "
        echo

        if ! [ -e "/Volumes/boot/ssh" ]; then
            echo "Enabling SSH... "
            touch "/Volumes/boot/ssh"
        fi

        read -p "Enter your WiFi SSID " ssid
        if [ -n "$ssid" ]; then
            read -p "Enter your WiFi password " psk
            echo "Setting up WiFi... SSID: \"$ssid\", PWD: \"$psk\""
            echo -e "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\nupdate_config=1\ncountry=GB\n\nnetwork={ ssid=\"$ssid\" psk=\"$psk\" key_mgmt=WPA-PSK }" > "/Volumes/boot/wpa_supplicant.conf"
        fi

        echo "Cleaning up... "
        diskutil unmountdisk /Volumes/boot
        cd ..
        rm -r tmp
        ok=1
    fi
done

echo Done