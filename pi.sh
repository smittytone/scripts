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
fi

read -n 1 -s -p "Insert SD card and press any key when it has appeared on the desktop "
echo
echo "Disk list... "
diskutil list

read -p "Enter the SD card's disk number (eg. 2 for /dev/disk2) " disknum

if [ -z "$disknum" ]; then
    echo "Invalid disk number -- exiting "
    exit 1
fi

unmountname="/dev/disk${disknum,,}"
copyname="/dev/rdisk${disknum,,}"

if diskutil unmountdisk "$unmountname"; then
    echo "Copying Raspberry Pi $pitype OS image to SD card... "
    if [ -e "tmp/p.img" ]; then
        sudo dd if=p.img of="$copyname" bs=1m
    fi

    read -n 1 -s -p "Press any key when 'boot' has appeared on the desktop "
    echo

    if [ -e "/Volumes/boot/ssh" ]; then
        echo "Enabling SSH... "
        touch "/Volumes/boot/ssh"
    fi

    echo "Cleaning up... "
    cd ..
    rm -r tmp
fi

echo Done