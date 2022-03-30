#!/usr/bin/env bash

# Backup to Uber-Disk Script
# Version 1.0.0

read -n 1 -r -p "Connect disk 4TB then press any key when it has mounted\n" key
if [ -d /Volumes/4TB ]; then
    read -n 1 -r -p "Connect disk MEDIA then press any key when it has mounted\n" key
	if [ -d /Volumes/Media ]; then
    	read -n 1 -r -p "Press any key to continue...\n" key
		echo "/Volumes/Media and /Volumes/4TB mounted. Backup Stage 1a commencing."
    	rsync -avz /Volumes/Media/ /Volumes/4TB/Backup/'Media Disk'/ --exclude=".*/" --exclude=".*"
    	echo "Backup Stage 1a Complete."
    else
    	echo "/Volumes/Media is not mounted."
    fi

	read -n 1 -r -p "Connect disk ATV then press any key when it has mounted\n" key
	if [ -d /Volumes/ATV ]; then
    	echo "/Volumes/ATV and /Volumes/4TB mounted. Backup Stage 2 commencing."
    	rsync -avz /Volumes/ATV/ /Volumes/4TB/Backup/ATV/ --exclude=".*/" --exclude=".*"
    	echo "Backup Stage 2 Complete. Please disconnect /Volumes/ATV, connect /Volumes/MEDIA2 and then run Backup script 3."
    else
    	echo "/Volumes/ATV is not mounted."
    fi

	read -n 1 -r -p "Connect disk MEDIA2 then press any key when it has mounted\n" key
	if [ -d /Volumes/MEDIA2 ]; then
    	echo "/Volumes/MEDIA2 and /Volumes/4TB mounted. Backup Stage 1 commencing."
    	rsync -avz /Volumes/MEDIA2/ /Volumes/4TB/Backup/'Media Disk'/ --exclude=".*/" --exclude=".*"
    	echo "Backup Stage 3 Complete. Please disconnect /Volumes/MEDIA 2 and /Volumes/4TB"
    	echo "Remember to back up /Users/smitty manually."
    else
    	echo "Disk MEDIA2 is not mounted."
    fi
else
    echo "Disk 4TB is not mounted -- backup cannot continue"
    exit 1
fi
