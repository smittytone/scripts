#!/bin/bash

# Backup to Server Script
# Version 1.1.2

clear
echo "Backup to Server"
read -n1 -s -p "Press [ENTER] to start" key
echo " "

pwd="$(pwd)"
bmk="/Users/smitty/.config/sync/bookmarks"
count=0

if [ ! -e $bmk ]; then
    echo "No bookmarks file found -- backup cannot continue"
    exit 1
fi

while IFS= read -r line; do 
    if [ ! -d $pwd/.mntpoint ]; then
        mkdir $pwd/.mntpoint
    fi
    
    if [ ! -d $pwd/.mntpoint/home ]; then
        mkdir $pwd/.mntpoint/home
    fi
    
    if [ ! -d $pwd/.mntpoint/music ]; then
        mkdir $pwd/.mntpoint/music
    fi
    
    mount -t smbfs //$line@192.168.0.3/music .mntpoint/music
    mount -t smbfs //$line@192.168.0.3/home .mntpoint/home
    ((count++))
done < $bmk

if [ $count -eq 0 ]; then
    echo "No bookmarks present -- backup cannot continue"
    exit 1
fi

if [ -d .mntpoint/home ]; then
    echo "Backing-up Comics and Books"
    rsync -avz ~/Documents/Comics/ .mntpoint/home/Comics --exclude ".*"
    rsync -avz ~/OneDrive/eBooks/ .mntpoint/home/eBooks --exclude ".*"
else
    echo "The server’s HOME partition is not mounted -- backup cannot continue"
fi

if [ -d .mntpoint/music ]; then
    echo "Backing-up Music"
    rsync -avz ~/Music/Alternative .mntpoint/music --exclude ".DS_Store"
    rsync -avz ~/Music/Classical .mntpoint/music --exclude ".DS_Store"
    rsync -avz ~/Music/Comedy .mntpoint/music --exclude ".DS_Store"
    rsync -avz ~/Music/'Doctor Who' .mntpoint/music --exclude ".DS_Store"
    rsync -avz ~/Music/Electronic .mntpoint/music --exclude ".DS_Store"
    rsync -avz ~/Music/Folk .mntpoint/music --exclude ".DS_Store"
    rsync -avz ~/Music/Metal .mntpoint/music --exclude ".DS_Store"
    rsync -avz ~/Music/Pop .mntpoint/music --exclude ".DS_Store"
    rsync -avz ~/Music/Rock .mntpoint/music --exclude ".DS_Store"
    rsync -avz ~/Music/SFX .mntpoint/music --exclude ".DS_Store"
    rsync -avz ~/Music/Soundtracks .mntpoint/music --exclude ".DS_Store"
    rsync -avz ~/Music/'Spoken Word' .mntpoint/music --exclude ".DS_Store"
    #rsync -avz ~/Music/Ringtones .mntpoint/music --exclude ".DS_Store"
    #rsync -avz ~/Music/Singles .mntpoint/music --exclude ".DS_Store"
else
    echo "The server's MUSIC directory is not mounted -- backup cannot continue"
fi

read -n1 -s -p "Press [ENTER] to finish" key
echo " "

# Unmount the shares; keep the operation success value for each
umount .mntpoint/music
success1=$?
umount .mntpoint/home
success2=$?

# Make sure the unmount operations succeeded, warning if not
if [[ $success1 -eq 0 && $success2 -eq 0 ]]; then
    # Remove the share mount points if both unmounts were successful
    rm -r .mntpoint
else
    if [ $success1 -ne 0 ]; then
        echo $pwd"/.mntpoint/music failed to unmount -- please unmount it manually and remove the mointpoint"
    fi

    if [ $success2 -ne 0 ]; then
        echo $pwd"/.mntpoint/home failed to unmount -- please unmount it manually and remove the mointpoint"
    fi
fi
