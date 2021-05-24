#!/bin/zsh

#
# todisk.zsh
#
# Backup to Disk Script
#
# @author    Tony Smith
# @copyright 2019-20, Tony Smith
# @version   3.3.1
# @license   MIT
#

APP_NAME=$(basename $0)
APP_NAME=${APP_NAME:t}
APP_VERSION="3.2.0"

typeset -i do_music=1
typeset -i do_books=1
target_vol=2TB-APFS
source_dir="$HOME"
d_sources=("/Comics" "/OneDrive/eBooks")
m_sources=("/Music/Alternative" "/Music/Classical" "/Music/Comedy" "/Music/Doctor Who"
           "/Music/Electronic" "/Music/Folk" "/Music/Pop" "/Music/Metal" "/Music/Rock"
           "/Music/SFX" "/Music/Singles" "/Music/Soundtracks" "/Music/Spoken Word"
           "/Music/Instrumental")
# FROM 3.2.0
# Add user fonts
f_sources=("/Library/Fonts")

# Functions
do_sync() {
    # Sync the source to the target
    # Arg 1 should be the source directory
    # Arg 2 should be the target directory
    local name="${1:t}"
    echo -n "Syncing ${name}... "

    # Prepare a readout of changed files ONLY (rsync does not do this)
    local list=$(rsync -az "$source_dir/$1" "$2" --itemize-changes --exclude ".DS_Store")
    local lines=$(grep '>' < <(echo -e "$list"))

    # Check we have files to report
    if [[ -n "$lines" ]]; then
        # Files were sync'd so count the total number
        typeset -i count=0
        local cols=$(tput cols)
        while IFS= read -r line; do
            ((count++))
        done <<< "$lines"
        echo "$count files changed:"
        # Output the files changed
        while IFS= read -r line; do
            local trimline=$(echo "$line" | cut -c 11-)
            if [[ -n "$trimline" ]]; then
                echo "    /$trimline"
            fi
        done <<< "$lines"
    else
        echo "no files changed"
    fi
}

show_help() {
    echo -e "todisk $APP_VERSION\n"
    echo -e "Usage:\n"
    echo -e "  todisk [-m] [-b] [<drive_name>]\n"
    echo -e "Options:\n"
    echo "  -m / --music   Backup music only. Default: backup both"
    echo "  -b / --books   Backup eBooks only. Default: backup both"
    echo "  <drive_name>   Optional drive name. Default: 2TB-APFS"
    echo
}

show_error() {
    echo "${APP_NAME} error: $1" 1>&2
}


# Runtime start
# Process the arguments
typeset -i arg_count=0
for arg in "$@"; do
    # Temporarily convert argument to lowercase, zsh-style
    check_arg=${arg:l}
    if [[ "$check_arg" = "--books" || "$check_arg" = "-b" ]]; then
        do_music=0
        ((arg_count += 1))
    elif [[ "$check_arg" = "--music" || "$check_arg" = "-m" ]]; then
        do_books=0
        ((arg_count += 1))
    elif [[ "$check_arg" = "--all" || "$check_arg" = "-a" ]]; then
        # Dummy arg to avoid presenting request to add disk
        ((arg_count += 1))
    elif [[ "$check_arg" = "--help" || "$check_arg" = "-h" ]]; then
        show_help
        exit 0
    else
        target_vol="$arg"
    fi
done

# Set the target path based on supplied disk name (or default)
target_path="/Volumes/$target_vol"

# Check that the user is not exluding both jobs
if [[ $do_books -eq 0 && $do_music -eq 0 ]]; then
    show_error "Mutually exclusive options set -- backup cannot continue"
    exit 1
fi

# If no options were specified, assume we're running interactively
# and invite the user to continue at their own pace
if [[ $arg_count -eq 0 ]]; then
    clear
    echo "Backup to Disk"
    # Get input, zsh style
    read -k -s "choice?Connect '$target_vol' then press [ENTER] when it has mounted "
    echo
fi

# Make sure the target disk is mounted
if [[ -d "$target_path" ]]; then
    echo "Disk '$target_vol' mounted."

    # Sync document sources
    if [[ $do_books -eq 1 ]]; then
        for source in "${d_sources[@]}"; do
            do_sync "$source" "$target_path"
        done

        # FROM 3.2.0
        # Add user fonts
        for source in "${f_sources[@]}"; do
            do_sync "$source" "$target_path"
        done
    fi

    # Sync music sources
    if [[ $do_music -eq 1 ]]; then
        for source in "${m_sources[@]}"; do
            do_sync "$source" "$target_path/Music"
        done
    fi
else
    echo "Disk '$target_vol' is not mounted."
fi
