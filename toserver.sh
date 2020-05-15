#!/usr/bin/env bash

# Backup to Server Script
# Version 4.0.0

count=0
success1=99
success2=99
musicMounted=0
homeMounted=0
doBooks=1
doMusic=1
server="NONE"
serverAuth=~/.config/sync/bookmarks
d_sources=("/Documents/Comics" "/OneDrive/eBooks")
m_sources=("/Music/Alternative" "/Music/Classical" "/Music/Comedy" "/Music/Doctor Who"
           "/Music/Electronic" "/Music/Folk" "/Music/Pop" "/Music/Metal" "/Music/Rock"
           "/Music/SFX" "/Music/Singles" "/Music/Soundtracks" "/Music/Spoken Word")

# From 4.0.0
# Functions
function doSync {
    # Sync the source to the target
    # Arg 1 should be the source directory
    # Arg 2 should be the target directory
    
    # Prepare a readout of changed files ONLY (rsync does not do this)
    list=$(rsync -az "$HOME/$1" "$2" --itemize-changes --exclude ".*")
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

# Check for either of the two possible switches:
#     --books - Backup the 'books' job only
#     --music - Backup the 'music' job only
#     --server - Address of the target server, eg. '192.168.0.1' or 'server.local'
# NOTE 'argCount' is a flag that stays 0 if no switches were included
argCount=0
argIsValue=0
for arg in "$@"
do
    if [ $argIsValue -eq 1 ]; then
        if [ $argCount -eq 1 ]; then
            server="$arg"
        fi
    else
        if [ $arg = "--books" ]; then
            doMusic=0
            ((argCount++))
        elif [ $arg = "--music" ]; then
            doBooks=0
            ((argCount++))
        elif [ $arg = "--server" ]; then
            argIsValue=1
            ((argCount++))
        else
            echo "Error: Unknown argument ($arg)"
            exit 1
        fi
    fi
done

# Check that the user is not exluding both jobs
if [[ $doBooks -eq 0 && $doMusic -eq 0 ]]; then
    echo "Mutually exclusive switches set -- backup cannot continue"
    exit 1
fi

# Check the 'bookmarks' file is present
if ! [ -f $serverAuth ]; then
    echo "No server auth file found -- backup cannot continue"
    exit 1
fi

# From 3.0.0
# Check for a valid server
if [ $server == "NONE" ]; then
    echo "No server addrss supplied -- backup cannot continue"
    exit 1
fi

# If no switches were specified, assume we're running interactively
# and invite the user to continue at their own pace
if [ $argCount -eq 0 ]; then
    clear
    echo "Backup to Server"
    read -n 1 -s -p "Press [ENTER] to start "
    echo
fi

# Read in the server auth file lines to make sure there IS a line to read
while IFS= read -r line; do
    # Make the mount point
    if ! [ -d mntpoint ]; then
        echo "Making mntpoint..."
        mkdir mntpoint
    fi

    # If we're doing the 'music' backup job, mount the relevant server store
    # and flag that it is mounted
    if [ $doMusic -eq 1 ]; then
        if ! [ -d mntpoint/music ]; then
            echo "Making mntpoint/music..."
            mkdir mntpoint/music
            echo "Mounting mntpoint/music..."
            if mount -t smbfs "//$line@$server/music" mntpoint/music; then
                musicMounted=1
            fi
        fi
    fi

    # If we're doing the 'books' backup job, mount the relevant server store
    # and flag that it is mounted
    if [ $doBooks -eq 1 ]; then
        if ! [ -d mntpoint/home ]; then
            echo "Making mntpoint/home..."
            mkdir mntpoint/home
            echo "Mounting mntpoint/home..."
            if mount -t smbfs "//$line@$server/home"  mntpoint/home; then
                homeMounted=1
            fi
        fi
    fi

    ((count++))
done < $serverAuth

# No server auth lines read? Then bail
if [ $count -eq 0 ]; then
    echo "No bookmarks present -- backup cannot continue"
    exit 1
fi

# Run the 'books' backup job
if [[ -d mntpoint/home && $homeMounted -eq 1 ]]; then
    echo "Backing-up Comics and Books..."
    for source in "${d_sources[@]}"; do
        doSync $source mntpoint/home
        #rsync -avz "$HOME/$source" mntpoint/home --exclude ".*"
    done
fi

# Run the 'music' backup job
if [[ -d mntpoint/music && $musicMounted -eq 1 ]]; then
    echo "Backing-up Music..."
    for source in "${m_sources[@]}"; do
        doSync $source mntpoint/music
        #rsync -avz "$HOME/$source" mntpoint/music --exclude ".*"
    done
fi

# If no switches were specified, assume we're running interactively
# and invite the user to continue at their own pace
if [ $argCount -eq 0 ]; then
    read -n 1 -s -p "Press [ENTER] to finish "
    echo
fi

# If we mounted the music store, unmount it now
# Exit with an error if we can't
if [ $musicMounted -eq 1 ]; then
    echo "Dismounting mntpoint/music..."
    umount mntpoint/music
    success1=$?

    if [ $success1 -ne 0 ]; then
        echo ~+"/mntpoint/music failed to unmount -- please unmount it manually and remove the mointpoint"
        exit 1
    fi
else
    success1=0
fi

# If we mounted the books store, unmount it now
# Exit with an error if we can't
if [ $homeMounted -eq 1 ]; then
    echo "Dismounting mntpoint/home..."
    umount mntpoint/home
    success2=$?

    if [ $success2 -ne 0 ]; then
        echo ~+"/mntpoint/home failed to unmount -- please unmount it manually and remove the mointpoint"
        exit 1
    fi
else
    success2=0
fi

# Make sure the unmount operations succeeded, warning if not
if [[ $success1 -eq 0 && $success2 -eq 0 ]]; then
    # Remove the share mount points if both unmounts were successful
    echo "Removing mntpoint..."
    rm -r mntpoint
else
    echo "Could not remove mntpoint -- exiting"
    exit 1
fi

echo Done
