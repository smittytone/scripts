#!/usr/bin/env bash

# Backup to Disk Script
# Version 2.1.1

target_vol=2TB-APFS
doMusic=1
doBooks=1
d_sources=("/Documents/Comics" "/OneDrive/eBooks")
m_sources=("/Music/Alternative" "/Music/Classical" "/Music/Comedy" "/Music/Doctor Who"
           "/Music/Electronic" "/Music/Folk" "/Music/Pop" "/Music/Metal" "/Music/Rock"
           "/Music/SFX" "/Music/Singles" "/Music/Soundtracks" "/Music/Spoken Word")

# Functions
function doSync {
    # Sync the source to the target
    # Arg 1 should be the source directory
    # Arg 2 should be the target directory
    name="${1##*/}"
    echo -n "Syncing $name"

    # Prepare a readout of changed files ONLY (rsync does not do this)
    list=$(rsync -az "$HOME/$1" "$2" --itemize-changes --exclude ".DS_Store")
    lines=$(grep '>' < <(echo -e "$list"))

    # Check we have files to report
    if [ -n "$lines" ]; then
        # Files were sync'd so count the total number
        count=0
        while IFS= read -r line; do
            ((count++))
        done <<< "$lines"
        echo "... $count files changed:"
        # Output the files changed
        while IFS= read -r line; do
            trimline=$(echo "$line" | cut -c 11-)
            if [ -n "$trimline" ]; then
                echo "/$trimline"
            fi
        done <<< "$lines"
    else
        echo "... no files changed"
    fi
}

# Runtime start
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

# Make sure the target disk is mounted
if [ -d "$target_path" ]; then
    echo "Disk '$target_vol' mounted."

    # Sync document sources
    if [ $doBooks -eq 1 ]; then
        for source in "${d_sources[@]}"; do
            doSync "$source" "$target_path"
        done
    fi

    # Sync music sources
    if [ $doMusic -eq 1 ]; then
        for source in "${m_sources[@]}"; do
            doSync "$source" "$target_path/Music"
        done
    fi
else
    echo "Disk '$target_vol' is not mounted."
fi
