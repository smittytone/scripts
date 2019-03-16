#!/bin/bash

# Backup to Server Script
# Version 1.1.0

pwd="$(pwd)"
read -n 1 -r -p "Press Enter to start" key

while IFS= read -r line; do 
    mkdir $pwd/.mntpoint
    mkdir $pwd/.mntpoint/home
    mkdir $pwd/.mntpoint/music
    mount -t smbfs //$line@192.168.0.3/music .mntpoint/music
    mount -t smbfs //$line@192.168.0.3/home .mntpoint/home
done < '/Users/smitty/.config/sync/bookmarks'

if [ -d .mntpoint/home ]; then
    echo -e "\nBacking-up Comics and Books"
    rsync -avz ~/Documents/Comics/ .mntpoint/home/Comics --exclude ".*"
	rsync -avz ~/OneDrive/eBooks/ .mntpoint/home/eBooks --exclude ".*"
else
    echo -e "\nThe server’s ‘home’ partition is not mounted -- backup cannot continue"
fi

if [ -d .mntpoint/music ]; then
    echo -e "Backing-up Music"
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

read -n 1 -r -p "Press Enter to finish" key

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
    if [ $success1 -eq 0 ]; then
		echo $pwd"/.mntpoint/music failed to unmount - please unmount it manually and remove the mointpoint"
	fi
	if [ $success2-eq 0 ]; then
		echo $pwd"/.mntpoint/home failed to unmount - please unmount it manually and remove the mointpoint"
	fi
fi
