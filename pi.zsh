#!/usr/bin/env zsh

# Pi Image Installation
#
# @version   2.0.0
# @author    Tony Smith (@smittytone)
# @copyright 2022
# @licence   MIT

# CONDITIONS
unsetopt nomatch

# GLOBALS
pi_type=Zero
pi_zip_file=NONE
app_version="2.0.0"
# Colours
red="\e[40;31m"
bold="\e[40;1m"
reset="\e[0m"
green="\e[40;32m"
yellow="\e[40;33m"
white="\e[40;97m"

# FUNCTIONS
show_error_and_exit() {
    echo -e "${red}${bold}[ERROR]${reset} ${1}"
    exit 1
}

get_pi_zip_file() {
    pi_zip_file=$(/bin/ls *.zip)
}

show_version() {
    echo -e "${green}Version ${app_version}${reset}"
}

# RUNTIME START
# Check input PiOS download location
URL=${1}

clear
echo -e "${bold}${white}macOS ${red}Raspberry Pi${white} Image Installer with optional WiFi setup${reset}"
show_version
read -k -s "choice?Install image on a standard Pi [P] or a Pi Zero [Z] image "
echo

choice=${choice:u}
if [[ "${choice}" != "P" && "${choice}" != "Z" ]] exit 0
if [[ "${choice}" = "P" ]] pi_type=Standard

if [[ ! -d "tmp" ]]; then
    mkdir tmp || show_error_and_exit "Could not create 'tmp' directory at this location"
fi

cd tmp || show_error_and_exit "Could not enter 'tmp' directory"

# Get the PiOS image
if [[ ! -e "p.img" ]]; then
    get_pi_zip_file
    if [[ ! -e "${pi_zip_file}" ]]; then
        # No zip file available, so download URL
        if [[ -z ${URL} ]]; then
            show_error_and_exit "No PiOS download URL specified.\nDownloads available at 'https://www.raspberrypi.com/software/operating-systems/'"
            # eg. https://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2022-01-28/2022-01-28-raspios-bullseye-armhf.zip
        fi
        if [[ ${URL:e:l} != "zip" ]] show_error_and_exit "Please supply a .zip file URL"

        # Get URL
        echo "Downloading Raspberry Pi ${pi_type} OS image... "
        curl -O -L -# ${URL}
        get_pi_zip_file
    fi

    read "choice?Enter SHA 256 or just hit [ENTER] to bypass this check "
    if [[ -n "${choice}" ]]; then
        echo "Calculating SHA256..."
        sha=$(shasum -a 256 ${pi_zip_file})
        sha=$(echo "${sha}" | cut -d " " -f 1)
        echo "Download SHA 256: ${sha}"
        echo " Entered SHA 256: ${choice}"
        if [[ ! "${choice}" = "${sha}" ]]; then
            echo "SHA256 values match"
        else
            show_error_and_exit "SHAs do not match -- do not proceed with this file"
        fi
    fi

    # Unzip the image file
    echo "Decompressing Raspberry Pi ${pi_type} OS image... "
    unzip ${pi_zip_file} > /dev/null 2>&1
    mv *.img p.img
fi

read -k -s "choice?Insert SD card and press any key when it has appeared on the desktop "
echo

typeset -i ok=0
while [[ ${ok} -eq 0 ]]; do
    echo "Disk list... "
    diskutil list external

    read "disk_num?Enter the SD card's disk number (eg. 2 for /dev/disk2) "

    if [ -z "${disk_num}" ]; then
        echo "Invalid disk number -- exiting "
        exit 1
    fi

    unmount_name="/dev/disk${disk_num}"
    dd_name="/dev/rdisk${disk_num}"

    if diskutil unmountdisk "${unmount_name}"; then
        # Copy across the PiOS disk image
        if [ -e "p.img" ]; then
            echo "About to copy Raspberry Pi ${pi_type} OS image to SD card ${unmount_name}... "
            read -k -s "key?Are you sure? [Y]es, [N]o or [C]ancel Setup "
            echo

            if [ ${key:u} != "Y" ]; then
                if [ ${key:u} = "C" ]; then
                    exit 0
                else
                    continue
                fi
            fi

            echo "Copying Raspberry Pi ${pi_type} OS image to SD card ${unmount_name}... "
            sudo dd if=p.img of="${dd_name}" bs=1m
        else
            show_error_and_exit "Missing Pi img file... aborting"
        fi

        read -k -s "choice?Press any key when 'boot' has appeared on the desktop "
        echo

        # Enable SSH
        if [[ ! -e "/Volumes/boot/ssh" ]]; then
            echo "Enabling SSH... "
            touch "/Volumes/boot/ssh"
        fi

        # Set up WiFi
        read "ssid?Enter your WiFi SSID "
        if [[ -n "${ssid}" ]]; then
            read "psk?Enter your WiFi password "
            echo "Setting up WiFi... SSID: \"${ssid}\", PWD: \"${psk}\""
            echo -e "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\nupdate_config=1\ncountry=GB\n\nnetwork={\n  ssid=\"${ssid}\"\n  psk=\"${psk}\"\n  key_mgmt=WPA-PSK\n}" > "/Volumes/boot/wpa_supplicant.conf"
        fi

        # Copy setup script for the user to run
        echo "Copying setup script to /boot... "
        src="$GIT/scripts/pinstall.sh"
        if [ "${pi_type}" = "Zero" ]; then
            src="$GIT/scripts/zinstall.sh"
        fi
        cp "${src}" /Volumes/boot

        # Fix mouse slowness
        echo "console=serial0,115200 console=tty1 root=PARTUUID=cebdaeb9-02 rootfstype=ext4 fsck.repair=yes rootwait quiet init=/usr/lib/raspi-config/init_resize.sh splash plymouth.ignore-serial-consoles usbhid.mousepoll=8" > /Volumes/boot/cmdline.txt

        # All done...
        echo "Cleaning up... "
        diskutil unmountdisk /Volumes/boot
        cd ..
        rm -r tmp
        ok=1
    fi
done

# Finished
echo "${bold}${green}Done${reset}"
