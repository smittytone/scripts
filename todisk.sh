#! /bin/bash

read -n1 -r -p "Connect MEDIA2 then press any key when it has mounted" key

if [ -d /Volumes/MEDIA2 ]; then
    echo -e "Disk MEDIA2 mounted.\n"
    echo "Syncing Comics"
    rsync -avz ~/Documents/Comics /Volumes/MEDIA2 --exclude ".DS_Store"
    echo "Syncing eBooks"
    rsync -avz ~/OneDrive/eBooks /Volumes/MEDIA2 --exclude ".DS_Store"
    echo "Syncing Music:Alternative"
    rsync -avz ~/Music/Alternative /Volumes/MEDIA2/Music --exclude ".DS_Store"
    echo "Syncing Music:Classical"
    rsync -avz ~/Music/Classical /Volumes/MEDIA2/Music --exclude ".DS_Store"
    echo "Syncing Music:Comedy"
    rsync -avz ~/Music/Comedy /Volumes/MEDIA2/Music --exclude ".DS_Store"
    echo "Syncing Music:Doctor Who"
    rsync -avz ~/Music/'Doctor Who' /Volumes/MEDIA2/Music --exclude ".DS_Store"
    echo "Syncing Music:Electronic"
    rsync -avz ~/Music/Electronic /Volumes/MEDIA2/Music --exclude ".DS_Store"
    echo "Syncing Music:Folk"
    rsync -avz ~/Music/Folk /Volumes/MEDIA2/Music --exclude ".DS_Store"
    echo "Syncing Music:Pop"
    rsync -avz ~/Music/Pop /Volumes/MEDIA2/Music --exclude ".DS_Store"
    echo "Syncing Music:Metal"
    rsync -avz ~/Music/Metal /Volumes/MEDIA2/Music --exclude ".DS_Store"
    echo "Syncing Music:Rock"
    rsync -avz ~/Music/Rock /Volumes/MEDIA2/Music --exclude ".DS_Store"
    echo "Syncing Music:SFX"
    rsync -avz ~/Music/SFX /Volumes/MEDIA2/Music --exclude ".DS_Store"
    echo "Syncing Music:Singles"
    rsync -avz ~/Music/Singles /Volumes/MEDIA2/Music --exclude ".DS_Store"
    echo "Syncing Music:Soundtracks"
    rsync -avz ~/Music/Soundtracks /Volumes/MEDIA2/Music --exclude ".DS_Store"
    echo "Syncing Music:Spoken Word"
    rsync -avz ~/Music/'Spoken Word' /Volumes/MEDIA2/Music --exclude ".DS_Store"
else
    echo "Disk MEDIA2 is not mounted."
fi