#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash

# Backup to Server Script
# Version 1.2.0

clear
echo "Backup to Server"
read -n 1 -s -p "Press [ENTER] to start "
echo

count=0
success1=99
success2=99
musicMounted=0
homeMounted=0
bookmark=~/.config/sync/bookmarks
d_sources=("/Documents/Comics" "/OneDrive/eBooks")
m_sources=("/Music/Alternative" "/Music/Classical" "/Music/Comedy" "/Music/Doctor Who"
           "/Music/Electronic" "/Music/Folk" "/Music/Pop" "/Music/Metal" "/Music/Rock"
           "/Music/SFX" "/Music/Singles" "/Music/Soundtracks" "/Music/Spoken Word")

if ! [ -f $bookmark ]; then
    echo "No bookmarks file found -- backup cannot continue"
    exit 1
fi

while IFS= read -r line; do
    if ! [ -d mntpoint ]; then
        echo "Making mntpoint..."
        mkdir mntpoint
    fi

    if ! [ -d mntpoint/music ]; then
        echo "Making mntpoint/music..."
        mkdir mntpoint/music
    fi

    if ! [ -d mntpoint/home ]; then
        echo "Making mntpoint/home..."
        mkdir mntpoint/home
    fi

    echo "Mounting mntpoint/music..."
    if mount -t smbfs "//$line@192.168.0.3/music" mntpoint/music; then
        musicMounted=1
    fi

    echo "Mounting mntpoint/home..."
    if mount -t smbfs "//$line@192.168.0.3/home"  mntpoint/home; then
        homeMounted=1
    fi

    ((count++))
done < $bookmark

if [ $count -eq 0 ]; then
    echo "No bookmarks present -- backup cannot continue"
    exit 1
fi

if [[ -d mntpoint/home && $homeMounted -eq 1 ]]; then
    echo "Backing-up Comics and Books..."
    for source in "${d_sources[@]}"; do
        rsync -avz "$HOME/$source" mntpoint/home --exclude ".DS_Store"
    done
else
    echo "The server’s HOME partition is not mounted -- backup cannot continue"
fi

if [[ -d mntpoint/music && $musicMounted -eq 1 ]]; then
    echo "Backing-up Music..."
    for source in "${m_sources[@]}"; do
        rsync -avz "$HOME/$source" mntpoint/music --exclude ".DS_Store"
    done
else
    echo "The server's MUSIC directory is not mounted -- backup cannot continue"
fi

read -n 1 -s -p "Press [ENTER] to finish "
echo

# Unmount the shares; keep the operation success value for each
if [ $musicMounted -eq 1 ]; then
    echo "Dismounting mntpoint/home..."
    umount mntpoint/music
    success1=$?
fi

if [ $homeMounted -eq 1 ]; then
    echo "Dismounting mntpoint/home..."
    umount mntpoint/home
    success2=$?
fi

# Make sure the unmount operations succeeded, warning if not
if [[ $success1 -eq 0 && $success2 -eq 0 ]]; then
    # Remove the share mount points if both unmounts were successful
    echo "Removing mntpoint..."
    rm -r mntpoint
else
    if [ $success1 -ne 0 ]; then
        echo ~+"/mntpoint/music failed to unmount -- please unmount it manually and remove the mointpoint"
    fi

    if [ $success2 -ne 0 ]; then
        echo ~+"/mntpoint/home failed to unmount -- please unmount it manually and remove the mointpoint"
    fi
fi

echo Done
