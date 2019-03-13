#!/bin/bash

# Backup to Server

read -n1 -r -p "Connect to server's HOME then press any key when it has mounted" key

if [ -d /Volumes/home ]; then
    echo -e "\nBacking-up Comics and Books"
    rsync -avz ~/Documents/Comics/ /Volumes/home/Comics --exclude ".*"
	rsync -avz ~/OneDrive/eBooks/ /Volumes/home/eBooks --exclude ".*"
else
    echo "The server’s ‘home’ partition is not mounted -- backup cannot continue"
fi

read -n1 -r -p "Connect to server's MUSIC then press any key when it has mounted" key

if [ -d /Volumes/music ]; then
    echo -e "\nBacking-up Music"
	rsync -avz ~/Music/Comedy /Volumes/music --exclude ".DS_Store"
	rsync -avz ~/Music/Metal /Volumes/music --exclude ".DS_Store"
	rsync -avz ~/Music/Electronic /Volumes/music --exclude ".DS_Store"
	#rsync -avz ~/Music/Singles /Volumes/music --exclude ".DS_Store"
	rsync -avz ~/Music/Pop /Volumes/music --exclude ".DS_Store"
	rsync -avz ~/Music/Alternative /Volumes/music --exclude ".DS_Store"
	rsync -avz ~/Music/Rock /Volumes/music --exclude ".DS_Store"
	rsync -avz ~/Music/Folk /Volumes/music --exclude ".DS_Store"
	rsync -avz ~/Music/Soundtracks /Volumes/music --exclude ".DS_Store"
	rsync -avz ~/Music/'Spoken Word' /Volumes/music --exclude ".DS_Store"
	rsync -avz ~/Music/'Doctor Who' /Volumes/music --exclude ".DS_Store"
	rsync -avz ~/Music/Classical /Volumes/music --exclude ".DS_Store"
	#rsync -avz ~/Music/Ringtones /Volumes/music --exclude ".DS_Store"
	rsync -avz ~/Music/SFX /Volumes/music --exclude ".DS_Store"
else
    echo "The server's MUSIC directory is not mounted -- backup cannot continue"
fi