#!/usr/bin/env bash

# Backup to Disk Script
# Version 2.0.2

target_vol=2TB-APFS
doMusic=1
doBooks=1
d_sources=("/Documents/Comics" "/OneDrive/eBooks")
m_sources=("/Music/Alternative" "/Music/Classical" "/Music/Comedy" "/Music/Doctor Who"
           "/Music/Electronic" "/Music/Folk" "/Music/Pop" "/Music/Metal" "/Music/Rock"
           "/Music/SFX" "/Music/Singles" "/Music/Soundtracks" "/Music/Spoken Word")

# Process the arguments
argCount=0
for arg in "$@"; do
    if [[ ${arg,,} = "--books" || ${arg,,} = "-b" ]]; then
        doMusic=0
        ((argCount++))
    elif [[ ${arg,,} = "--music" || ${arg,,} = "-m" ]]; then
        doBooks=0
        ((argCount++))
    elif [[ ${arg,,} = "--help" || ${arg,,} = "-h" ]]; then
        echo -e "todisk.sh\n"
        echo -e "Usage:\n"
        echo -e "  todisk.sh [-m] [-b] [<drive_name>]\n"
        echo -e "sOptions:\n"
        echo "  -m / --music   Backup music only. Default: backup both"
        echo "  -b / --books   Backup eBooks only. Default: backup both"
        echo "  <drive_name>   Optional drive name. Default: 2TB-APFS"
        echo
        exit 0
    else
        target_vol=$arg
    fi
done

# Set the target path based on supplied disk name (or default)
target_path="/Volumes/$target_vol"

# Check that the user is not exluding both jobs
if [[ $doBooks -eq 0 && $doMusic -eq 0 ]]; then
    echo "Mutually exclusive switches set -- backup cannot continue"
    exit 1
fi

# If no switches were specified, assume we're running interactively
# and invite the user to continue at their own pace
if [ $argCount -eq 0 ]; then
    clear
    echo "Backup to Disk"
    read -n 1 -s -p "Connect '$target_vol' then press [ENTER] when it has mounted"
    echo
fi

if [ -d "$target_path" ]; then
    echo "Disk '$target_vol' mounted."

    # Sync document sources
    if [ $doBooks -eq 1 ]; then
        for source in "${d_sources[@]}"; do
            name="${source##*/}"
            echo "Syncing $name"
            rsync -az "$HOME/$source" "$target_path" --exclude ".DS_Store"
        done
    fi

    # Sync music sources
    if [ $doMusic -eq 1 ]; then
        for source in "${m_sources[@]}"; do
            name="${source##*/}"
            echo "Syncing $name music"
            rsync -az "$HOME/$source" "$target_path/Music" --exclude ".DS_Store"
        done
    fi
else
    echo "Disk '$target_vol' is not mounted."
fi
