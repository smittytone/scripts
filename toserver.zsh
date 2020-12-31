#!/bin/zsh

#
# toserver.zsh
#
# Backup to Server Script
#
# @author    Tony Smith
# @copyright 2019-20, Tony Smith
# @version   5.5.0
# @license   MIT
#

APP_NAME=$(basename $0)
APP_NAME=${APP_NAME:t}
APP_VERSION="5.4.0"

typeset -i do_music=1
typeset -i do_books=1
typeset -i do_docus=1
typeset -i count=0
typeset -i music_mounted=0
typeset -i home_mounted=0
typeset -i do_books=1
typeset -i do_music=1
server_auth="$HOME/.config/sync/bookmarks"
target_vol="NONE"
d_sources=("/Comics" "/OneDrive/eBooks")
m_sources=("/Music/Alternative" "/Music/Classical" "/Music/Comedy" "/Music/Doctor Who"
           "/Music/Electronic" "/Music/Folk" "/Music/Pop" "/Music/Metal" "/Music/Rock"
           "/Music/SFX" "/Music/Singles" "/Music/Soundtracks" "/Music/Spoken Word"
           "/Music/Instrumental")

# FROM 5.2.0
# Add user fonts
b_sources=("/Library/Fonts" "/Pictures" "/Documents" "/Downloads")

# From 4.0.0
# Functions
do_sync() {
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

# FROM 5.0.2
show_error() {
    echo "${APP_NAME} error: $1"
}

# FROM 5.1.0
# FROM 5.4.0 - add general docs backup
show_help() {
    echo -e "toserver $APP_VERSION\n"
    echo -e "Usage:\n"
    echo -e "  toserver [-m] [-b] [-d] [<server_addr>]\n"
    echo -e "Options:\n"
    echo "  -m / --music   Backup music only. Default: backup all"
    echo "  -b / --books   Backup eBooks only. Default: backup all"
    echo "  -d / --docs    Backup docs only. Default: backup all"
    echo "  <server_addr>  Server server name, eg. '192.168.0.1' or 'server.local'"
    echo
}

# Runtime start
# Process the arguments
typeset -i arg_count=0
for arg in "$@"; do
    # Temporarily convert argument to lowercase, zsh-style
    check_arg=${arg:l}
    if [[ "$check_arg" = "--books" || "$check_arg" = "-b" ]]; then
        do_music=0
        do_docus=0
        ((arg_count += 1))
    elif [[ "$check_arg" = "--music" || "$check_arg" = "-m" ]]; then
        do_books=0
        do_docus=0
        ((arg_count += 1))
    elif [[ "$check_arg" = "--docs" || "$check_arg" = "-d" ]]; then
        do_books=0
        do_music=0
        ((arg_count += 1))
    elif [[ "$check_arg" = "--help" || "$check_arg" = "-h" ]]; then
        show_help
        exit 0
    else
        target_vol="$arg"
        ((arg_count += 1))
    fi
done

# Check that the user is not exluding both jobs
if [[ $do_books -eq 0 && $do_music -eq 0 && $do_docus -eq 0 ]]; then
    show_error "Mutually exclusive options set -- backup cannot continue"
    exit 1
fi

# Check the 'bookmarks' file is present
if [[ ! -f $server_auth ]]; then
    show_error "No server auth file found -- backup cannot continue"
    exit 1
fi

# From 3.0.0
# Check for a valid server
if [[ $target_vol = "NONE" ]]; then
    show_error "No server address supplied -- backup cannot continue"
    exit 1
fi

# If no options were specified, assume we're running interactively
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
                if mount -t smbfs -o nobrowse "//$line@$target_vol/music" mntpoint/music; then
                    music_mounted=1
                fi
            fi
        fi
    fi

    # If we're doing the 'books' backup job, mount the relevant server store
    # and flag that it is mounted
    if [[ $do_books -eq 1 || $do_docus -eq 1 ]]; then
        if [[ ! -d mntpoint/home ]]; then
            echo "Making mntpoint/home..."
            if mkdir mntpoint/home; then
                echo "Mounting mntpoint/home..."
                if mount -t smbfs -o nobrowse "//$line@$target_vol/home"  mntpoint/home; then
                    home_mounted=1
                fi
            fi
        fi
    fi

    ((count += 1))
done < $server_auth

# No server auth lines read? Then bail
if [[ $count -eq 0 ]]; then
    show_error "No bookmarks present -- backup cannot continue"
    exit 1
fi

# Run the 'books' backup job
if [[ -d mntpoint/home && $home_mounted -eq 1 ]]; then
    if [[ $do_books -eq 1 ]]; then
        echo "Backing-up Comics and Books..."
        for source in "${d_sources[@]}"; do
            do_sync "$source" mntpoint/home
        done
    fi

    # FROM 5.4.0
    # Run the 'docs' backup job
    if [[ $do_docus -eq 1 ]]; then
        echo "Backing-up Documents..."
        for source in "${b_sources[@]}"; do
            do_sync "$source" mntpoint/home
        done
    fi
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
if [[ $music_mounted -eq 1 ]]; then
    echo "Dismounting mntpoint/music..."
    if ! umount mntpoint/music; then
        show_error "/mntpoint/music failed to unmount -- please unmount it manually and remove the mointpoint"
        exit 1
    fi
fi

# If we mounted the books store, unmount it now
# Exit with an error if we can't
if [[ $home_mounted -eq 1 ]]; then
    echo "Dismounting mntpoint/home..."
    if ! umount mntpoint/home; then
        show_error "/mntpoint/home failed to unmount -- please unmount it manually and remove the mointpoint"
        exit 1
    fi
fi

# Make sure the unmount operations succeeded, warning if not
echo "Removing mntpoint..."
if rm -r mntpoint; then
    echo "Done"
else
    show_error "Could not remove mntpoint -- exiting"
    exit 1
fi
