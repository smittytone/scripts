#!/bin/bash

# Deploy compiled firmare to RP2040-based board
#
# Usage:
#   ./deploy {path/to/uf2}
#
# @author    Tony Smith
# @copyright 2022, Tony Smith
# @version   1.1.0
# @license   MIT

APP_NAME=$(basename $0)
APP_NAME=${APP_NAME:t}
APP_VERSION="1.1.0"

# Display an error string and bail
show_error_and_exit() {
    echo "[ERROR] $1"
    exit 1
}

# List available Pico and, if necessary, get the
# user to choose the one they want to copy to
dlist() {
    # Get deviece list by platform
    if [[ ${1} = Darwin ]]; then
        devices=($(/bin/ls /dev/cu.usb* 2>/dev/null))
    else
        devices=($(/bin/ls /dev/ttyACM* 2>/dev/null))
    fi

    if [ ${#devices[@]} -gt 0 ]; then
        # If there are multiple devices, get the user to choose one
        if [[ ${#devices[@]} -gt 1 ]]; then
            # List the devices
            count=1
            for device in "${devices[@]}"; do
                echo "$count. $device"
                ((count+=1))
            done

            # Get the user to pick one
            acount=$((count-1))
            while true; do
                read -p "Enter device number (1-${acount}) " dev_num
                [[ ${dev_num} -gt 0 && ${dev_num} -lt ${count} ]] && break
            done

            # Record the selected device
            ((dev_num-=1))
            devices=${devices[${dev_num}]}
        fi
    else
        show_error_and_exit "No devices connected"
    fi
}

if [[ -z ${1} ]]; then
    echo "Usage: deploy {path/to/uf2}"
    exit 0
fi

if [[ ! -f ${1} ]]; then
    echo "[ERROR] ${1} cannot be found"
    exit 1
fi

# What platform are we running on?
platform=$(uname)

# Get any connected devices
# Only device, or choice of device, will be in ${devices}
dlist ${platform}

# Put the selected Pico onto BOOTSEL mode
if [[ ${platform} = Darwin ]]; then
    # macOS mount path
    pico_path=/Volumes/RPI-RP2
    stty -f ${devices} 1200 || show_error_and_exit "Could not connect to device ${devices}"
else
    # NOTE This is for Raspberry Pi -- you may need to change it
    #      depending on how you or your OS locate USB drive mount points
    pico_path="/media/$USER/RPI-RP2"
    stty -F ${devices} 1200 || show_error_and_exit "Could not connect to device ${devices}"

    # Allow for command line usage -- ie. not in a GUI terminal
    # Command line is SHLVL 1, so script is SHLVL 2 (under the GUI we'd be a SHLVL 3)
    if [[ $SHLVL -eq 2 ]]; then
        # Mount the disk, but allow time for it to appear (not immediate on RPi)
        sleep 5
        rp2_disk=$(sudo fdisk -l | grep FAT16 | cut -f 1 -d ' ')
        if [[ -z ${rp2_disk} ]]; then
            show_error_and_exit "Could not see device ${devices}"
        fi

        sudo mkdir ${pico_path} || show_error_and_exit "Could not make mount point ${pico_path}"
        sudo mount ${rp2_disk} ${pico_path} -o rw || show_error_and_exit "Could not mount device ${devices}"
    fi    
fi

echo "Waiting for Pico to mount..."
count=0
while [ ! -d ${pico_path} ]; do
    sleep 0.1
    ((count+=1))
    [[ ${count} -eq 200 ]] && show_error_and_exit "Pico mount timed out"
done
sleep 0.5

# Copy the target file
echo "Copying ${1} to ${devices}..."
if [[ ${platform} = Darwin ]]; then
    cp ${1} ${pico_path}
else
    sudo cp ${1} ${pico_path}
    if [[ $SHLVL -eq 2 ]]; then
        # We're at the command line, so unmount (RPi GUI does this automatically)
        sudo umount ${rp2_disk} && echo "Pico unmounted" && sudo rm -rf ${pico_path} && echo "Mountpoint removed"
    fi
fi
echo Done
