#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash

# Backup to Disk Script
# Version 1.1.0

target_vol=2TB-APFS
target_path="/Volumes/$target_vol"

d_sources=("/Documents/Comics" "/OneDrive/eBooks")
m_sources=("/Music/Alternative" "/Music/Classical" "/Music/Comedy" "/Music/Doctor Who"
           "/Music/Electronic" "/Music/Folk" "/Music/Pop" "/Music/Metal" "/Music/Rock"
           "/Music/SFX" "/Music/Singles" "/Music/Soundtracks" "/Music/Spoken Word")

clear
echo "Backup to Disk"
read -n 1 -s -p "Connect '$target_vol' then press [ENTER] when it has mounted"
echo

if [ -d "$target_path" ]; then
    echo "Disk '$target_vol' mounted."
    # Sync document sources
    for source in "${d_sources[@]}"; do
        name="${source##*/}"
        echo "Syncing $name"
        rsync -avz "$HOME/$source" "$target_path" --exclude ".DS_Store"
    done

    # Sync music sources
    for source in "${m_sources[@]}"; do
        name="${source##*/}"
        echo "Syncing $name music"
        rsync -avz "$HOME/$source" "$target_path/Music" --exclude ".DS_Store"
    done
else
    echo "Disk '$target_vol' is not mounted."
fi