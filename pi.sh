#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash
#      but I use brew-installed bash under macOS

# Pi Image Installation
# Version 1.0.2

url=https://downloads.raspberrypi.org/raspbian_latest

clear
echo "macOS Raspberry Pi Image Installer with optional WiFi setup"
read -n 1 -s -p "Install Standard Pi [P] or Pi Zero [Z] image " choice
echo

choice=${choice^^*}

if [[ "$choice" != "P" && "$choice" != "Z" ]]; then
    exit 0
fi

pitype=Zero

if [ "$choice" = "P" ]; then
    pitype=Standard
fi

if ! [ -e "tmp" ]; then
    mkdir tmp
fi

cd tmp || exit 1

if ! [ -e "p.img" ]; then
    echo "Downloading Raspberry Pi $pitype OS image... "
    curl -O -L -# "$url"

    read -p "Enter SHA 256 or [ENTER] to bypass this check " choice
    if [ -n "$choice" ]; then
        sha=$(shasum -a 256 raspbian_latest)
        echo "Download SHA 256: $sha"
        echo " Entered SHA 256: $choice"
        if [ "$choice" = "$sha" ]; then
            echo "MATCH"
        else
            echo "SHAs do not match -- do not proceed with this file"
            exit 1
        fi
    fi

    echo "Decompressing Raspberry Pi $pitype OS image... "
    mv raspbian_latest r.zip
    unzip r.zip
    mv *.img p.img
fi

read -n 1 -s -p "Insert SD card and press any key when it has appeared on the desktop "
echo

ok=0
while [ $ok -eq 0 ]; do
    echo "Disk list... "
    diskutil list

    read -p "Enter the SD card's disk number (eg. 2 for /dev/disk2) " disknum

    if [ -z "$disknum" ]; then
        echo "Invalid disk number -- exiting "
        exit 1
    fi

    unmountname="/dev/disk$disknum"
    ddname="/dev/rdisk$disknum"

    if diskutil unmountdisk "$unmountname"; then

        if [ -e "p.img" ]; then
            echo "About to copy Raspberry Pi $pitype OS image to SD card $unmountname... "

            read -n 1 -s -p "Are you sure? [Y]es, [N]o or [C]ancel " key
            echo

            if [ ${key^^*} != "Y" ]; then
                if [ ${key^^*} = "C" ]; then
                    exit 0
                else
                    continue
                fi
            fi

            echo "Copying Raspberry Pi $pitype OS image to SD card $unmountname... "
            sudo dd if=p.img of="$ddname" bs=1m
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
            echo -e "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\nupdate_config=1\ncountry=GB\n\nnetwork={\n  ssid=\"$ssid\"\n  psk=\"$psk\"\n  key_mgmt=WPA-PSK\n}" > "/Volumes/boot/wpa_supplicant.conf"
        fi

        echo "Cleaning up... "
        diskutil unmountdisk /Volumes/boot
        cd ..
        rm -r tmp
        ok=1
    fi
done

echo Done