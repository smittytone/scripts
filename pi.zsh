#!/usr/bin/env zsh

# Pi Image Installation
#
# @version   2.1.1
# @author    Tony Smith (@smittytone)
# @copyright 2022
# @licence   MIT

# CONDITIONS
unsetopt nomatch

# GLOBALS
pi_type=Standard
pi_zip_file=NONE
app_version="2.1.1"
debug=0
# Colours
red="\e[40;31m"
rasp="\e[107;31m"
bold="\e[40;1m"
reset="\e[0m"
green="\e[40;32m"
yellow="\e[40;33m"
white="\e[40;97m"
head="\e[107;30m"

# FUNCTIONS
show_error_and_exit() {
    echo -e "${red}${bold}[ERROR]${reset} ${1}"
    exit 1
}

get_pi_zip_file() {
    show_debug "File type: ${1:e:l}"
    if [[ "${1:e:l}" == "zip" ]]; then
        pi_zip_file=$(/bin/ls *.zip 2> /dev/null)
    else
        pi_zip_file=$(/bin/ls *.xz 2> /dev/null)
    fi
}

show_version() {
    echo -e "${green}Version ${app_version}${reset}"
}

show_debug() {
    if [[ $debug -eq 1 ]]; then
        echo -e "${yellow}${bold}[DEBUG]${reset} $1"
    fi
}

# RUNTIME START
# Check input PiOS download location
for var in "$@"; do
    if [[ ${var:u} = "-D" || ${var:u} = "--DEBUG" ]]; then
        debug=1
    else
        URL=${var}
    fi
done

# Get the Mac CPU type for the OpenSSL location
# NOTE Actual values will depend on how you set up Homebrew
CPU=$(uname -p)
if [[ "$CPU" == "arm" ]]; then
    openssl_path=/opt/homebrew/opt/openssl/bin/openssl
else
    openssl_path=/usr/local/opt/openssl/bin/openssl
fi

if [[ ! -f "${openssl_path}" ]]; then
    show_error_and_exit "This app requires OpenSSL. Please install it using Homebrew (brew install openssl@3) and then retry this app"
fi

# Show intro
clear
echo -e "${bold}${head} macOS ${rasp}Raspberry Pi${head} Image Installer with Optional WiFi Setup ${reset}"
show_version
read -k -s "choice?Install for a standard Pi [P] or a Pi Zero [Z] image (default: standard) "
echo

choice=${choice:u}
if [[ "${choice}" = "Z" ]] pi_type=Zero

if [[ ! -e tmp ]]; then
    show_debug "No tmp directory... creating one"
    mkdir tmp || show_error_and_exit "Could not create 'tmp' directory at this location"
fi

cd tmp || show_error_and_exit "Could not enter 'tmp' directory"

# Get the PiOS image
if [[ ! -f p.img ]]; then
    get_pi_zip_file ${URL}
    show_debug "Archive file: ${pi_zip_file}"

    if [[ ! -f "${pi_zip_file}" ]]; then
        # No zip file available, so download URL
        if [[ -z ${URL} ]]; then
            show_error_and_exit "No PiOS download URL specified.\nDownloads available at 'https://www.raspberrypi.com/software/operating-systems/'"
            # eg. https://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2022-01-28/2022-01-28-raspios-bullseye-armhf.zip
        fi
        if [[ ${URL:e:l} != "zip" && ${URL:e:l} != "xz" ]] show_error_and_exit "Please supply an archive file URL"

        # Get URL
        echo "Downloading Raspberry Pi ${pi_type} OS image... "
        curl -O -L -# ${URL}
        get_pi_zip_file ${URL}
        show_debug "Archive file: ${pi_zip_file}"
    fi

    read "choice?Enter SHA 256 or just hit [ENTER] to bypass this check "
    if [[ -n "${choice}" ]]; then
        echo "Calculating SHA256..."
        sha=$(shasum -a 256 ${pi_zip_file})
        sha=$(echo "${sha}" | cut -d " " -f 1)
        echo "Download SHA 256: ${sha}"
        echo " Entered SHA 256: ${choice}"
        if [[ "${choice}" = "${sha}" ]]; then
            echo "SHA256 values match"
        else
            show_error_and_exit "SHAs do not match -- do not proceed with this file"
        fi
    fi

    # Unzip the image file
    echo "Decompressing Raspberry Pi ${pi_type} OS image... "
    if [[ ${URL:e:l} == "zip" ]]; then
        unzip -o ${pi_zip_file} > /dev/null 2>&1
    else
        xz -d -k ${pi_zip_file} > /dev/null 2>&1
    fi

    mv *.img p.img
else
    show_debug "PiOS image already downloaded"
fi

read -k -s "choice?Insert SD card and press any key when it has appeared on the desktop "
echo

typeset -i ok=0
while [[ ${ok} -eq 0 ]]; do
    echo "Disk list... "
    # NOTE Adding 'external' to following command doesn't always work:
    #      Mac SD card slots list cards is internal (macOS 12.4 at least)
    diskutil list

    read "disk_num?Enter the SD card's disk number (eg. 2 for /dev/disk2) "

    if [ -z "${disk_num}" ]; then
        echo "Invalid disk number -- exiting "
        exit 1
    fi

    unmount_name="/dev/disk${disk_num}"
    dd_name="/dev/rdisk${disk_num}"

    if diskutil unmountdisk "${unmount_name}"; then
        # Copy across the PiOS disk image
        if [ -f p.img ]; then
            echo "About to copy Raspberry Pi ${pi_type} OS image to SD card ${unmount_name}... "
            read -k -s "key?Are you sure? [Y]es, [N]o or [E]xit Setup "
            echo

            if [[ ${key:u} != "Y" ]]; then
                if [[ ${key:u} = "E" ]]; then
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

        # Set up user account
        while; do
            read "username?Enter your new system username "
            if [[ -n "${username}" ]]; then
                break
            else
                echo "[ERROR] Please enter a non-zero username"
            fi
        done

        while; do
            read "password?Enter your new system password "
            if [[ -n "${password}" ]]; then
                break
            else
                echo "[ERROR] Please enter a non-zero password"
            fi
        done

        echo "Setting up a user account for \"${username}\""
        epw=$(echo "${password}" | "${openssl_path}" passwd -6 -stdin)
        echo "${username}:${epw}" > "/Volumes/boot/userconf.txt"

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
        in_file=$(cat /Volumes/boot/cmdline.txt)
        in_file=${in_file:0:-1}
        echo "${in_file} usbhid.mousepoll=8" >> /Volumes/boot/cmdline.txt

        # All done...
        echo "Cleaning up... "
        sudo diskutil unmountdisk /Volumes/boot
        cd ..
        rm -r tmp
        ok=1
    fi
done

# Finished
echo "${bold}${green}Done${reset}"
