#!/bin/zsh

# Backup to Server Script
# Version 5.0.1

count=0
success_1=99
success_2=99
music_mounted=0
home_mounted=0
do_books=1
do_music=1
server="NONE"
server_auth=~/.config/sync/bookmarks
d_sources=("/Comics" "/OneDrive/eBooks")
m_sources=("/Music/Alternative" "/Music/Classical" "/Music/Comedy" "/Music/Doctor Who"
           "/Music/Electronic" "/Music/Folk" "/Music/Pop" "/Music/Metal" "/Music/Rock"
           "/Music/SFX" "/Music/Singles" "/Music/Soundtracks" "/Music/Spoken Word")

# From 4.0.0
# Functions
function do_sync {
    # Sync the source to the target
    # Arg 1 should be the source directory
    # Arg 2 should be the target directory
    name=${1:t}
    echo -n "  ${name}... "

    # Prepare a readout of changed files ONLY (rsync does not do this)
    list=$(rsync -az "$HOME/$1" "$2" --itemize-changes --exclude ".*")
    lines=$(grep '>' < <(echo -e "$list"))

    # Check we have files to report
    if [[ -n "$lines" ]]; then
        # Files were sync'd so count the total number
        count=0
        while IFS= read -r line; do
            ((count += 1))
        done <<< "$lines"
        echo "$count files changed:"
        # Output the files changed
        while IFS= read -r line; do
            trimline=$(echo "$line" | cut -c 11-)
            if [ -n "$trimline" ]; then
                echo "    /$trimline"
            fi
        done <<< "$lines"
    else
        echo "no files changed"
    fi
}

# Check for either of the two possible switches:
#     --books - Backup the 'books' job only
#     --music - Backup the 'music' job only
#     --server - Address of the target server, eg. '192.168.0.1' or 'server.local'
# NOTE 'argCount' is a flag that stays 0 if no switches were included
typeset -i arg_count=0
typeset -i arg_is_value=0
for arg in "$@"
do
    if [[ $arg_is_value -eq 1 ]]; then
        if [[ $arg_count -eq 1 ]]; then
            server="$arg"
        fi
    else
        if [[ $arg = "--books" ]]; then
            do_music=0
            ((arg_count += 1))
        elif [[ $arg = "--music" ]]; then
            do_books=0
            ((arg_count += 1))
        elif [[ $arg = "--server" ]]; then
            arg_is_value=1
            ((arg_count += 1))
        else
            echo "Error: Unknown argument ($arg)"
            exit 1
        fi
    fi
done

# Check that the user is not exluding both jobs
if [[ $do_books -eq 0 && $do_music -eq 0 ]]; then
    echo "No sources set -- backup cannot continue"
    exit 1
fi

# Check the 'bookmarks' file is present
if [[ ! -f $server_auth ]]; then
    echo "No server auth file found -- backup cannot continue"
    exit 1
fi

# From 3.0.0
# Check for a valid server
if [[ $server = "NONE" ]]; then
    echo "No server addrss supplied -- backup cannot continue"
    exit 1
fi

# If no switches were specified, assume we're running interactively
# and invite the user to continue at their own pace
if [[ $arg_count -eq 0 ]]; then
    clear
    read -k -s "choice?Press [ENTER] to start "
    echo
fi

# Read in the server auth file lines to make sure there IS a line to read
# File is plain text with a single string: <username>:<password>
# See 'server_auth' setting above for file's location
while IFS= read -r line; do
    # Make the mount point
    if [[ ! -d mntpoint ]]; then
        echo "Making mntpoint..."
        mkdir mntpoint
    fi

    # If we're doing the 'music' backup job, mount the relevant server store
    # and flag that it is mounted
    if [[ $do_music -eq 1 ]]; then
        if [[ ! -d mntpoint/music ]]; then
            echo "Making mntpoint/music..."
            if mkdir mntpoint/music; then
                echo "Mounting mntpoint/music..."
                if mount -t smbfs "//$line@$server/music" mntpoint/music; then
                    music_mounted=1
                fi
            fi
        fi
    fi

    # If we're doing the 'books' backup job, mount the relevant server store
    # and flag that it is mounted
    if [[ $do_books -eq 1 ]]; then
        if [[ ! -d mntpoint/home ]]; then
            echo "Making mntpoint/home..."
            if mkdir mntpoint/home; then
                echo "Mounting mntpoint/home..."
                if mount -t smbfs "//$line@$server/home"  mntpoint/home; then
                    home_mounted=1
                fi
            fi
        fi
    fi

    ((count += 1))
done < $server_auth

# No server auth lines read? Then bail
if [ $count -eq 0 ]; then
    echo "No bookmarks present -- backup cannot continue"
    exit 1
fi

# Run the 'books' backup job
if [[ -d mntpoint/home && $home_mounted -eq 1 ]]; then
    echo "Backing-up Comics and Books..."
    for source in "${d_sources[@]}"; do
        do_sync "$source" mntpoint/home
    done
fi

# Run the 'music' backup job
if [[ -d mntpoint/music && $music_mounted -eq 1 ]]; then
    echo "Backing-up Music..."
    for source in "${m_sources[@]}"; do
        do_sync "$source" mntpoint/music
    done
fi

# If no switches were specified, assume we're running interactively
# and invite the user to continue at their own pace
if [[ $arg_count -eq 0 ]]; then
    read -k -s "choice?Press [ENTER] to finish "
    echo
fi

# If we mounted the music store, unmount it now
# Exit with an error if we can't
success_1=1
if [[ $music_mounted -eq 1 ]]; then
    echo "Dismounting mntpoint/music..."
    if umount mntpoint/music; then
        success_1=0
    else
        echo ~+"/mntpoint/music failed to unmount -- please unmount it manually and remove the mointpoint"
        exit 1
    fi
fi

# If we mounted the books store, unmount it now
# Exit with an error if we can't
success_2=1
if [[ $home_mounted -eq 1 ]]; then
    echo "Dismounting mntpoint/home..."
    if umount mntpoint/home; then
        success_2=0
    else
        echo ~+"/mntpoint/home failed to unmount -- please unmount it manually and remove the mointpoint"
        exit 1
    fi
fi

# Make sure the unmount operations succeeded, warning if not
if [[ $success_1 -eq 0 && $success_2 -eq 0 ]]; then
    # Remove the share mount points if both unmounts were successful
    echo "Removing mntpoint..."
    rm -r mntpoint
else
    echo "Could not remove mntpoint -- exiting"
    exit 1
fi

echo Done