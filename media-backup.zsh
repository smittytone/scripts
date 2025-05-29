#!/bin/zsh

#
# media-backup.zsh
#
# Backup to Disk Script
#
# @author    Tony Smith
# @copyright 2025, Tony Smith
# @version   1.0.1
# @license   MIT
#

typeset -i do_music=1
typeset -i do_books=1
target_disk="500GB"
# Arrays of directory paths: local machine, music server mount, home server mount
local_sources=('Library/Mobile Documents/com~apple~CloudDocs/Documents/eBooks')
music_sources=(Alternative Classical Comedy 'Doctor Who' Electronic Folk Pop Metal Rock
               SFX Singles Soundtracks 'Spoken Word' Instrumental)
home_sources=(Comics)

bold=$(tput bold)
normal=$(tput sgr0)

# Functions
do_sync() {
    # Sync the source to the target
    # Arg 1 should be the source directory
    # Arg 2 should be the target directory
    local name="${1:t}"
    echo -n "  Syncing ${name}... "

    # Prepare a readout of changed files ONLY (rsync does not do this)
    local list=$(rsync -az "$1" "$2" -i --exclude ".DS_Store")
    local lines=$(grep '>' < <(echo -e "$list"))

    # Check we have files to report
    if [[ -n "$lines" ]]; then
        # Files were sync'd so count the total number
        typeset -i count=0
        local cols=$(tput cols)
        while IFS= read -r line; do
            ((count++))
        done <<< "${lines}"
        echo "${count} files changed:"
        # Output the files changed
        count=1
        while IFS= read -r line; do
            # rsync 2.6.x use 'cut -c 11-'; below is for 3.3.x
            local trimmed=$(echo "${line}" | cut -c 14-)
            number=$(printf "%03d" ${count})
            [[ -n "${trimmed}" ]] && echo "    ${number}. /${trimmed}"
            ((count++))
        done <<< "$lines"
    else
        echo "no files changed"
    fi
}

show_help() {
    echo "media-backup"
    echo "Usage:"
    echo "  media-backup {-m|-b} {drive_name}"
    echo "Options:"
    echo "  -m / --music   Backup music only. Default: backup both"
    echo "  -b / --books   Backup eBooks only. Default: backup both"
    echo "  <drive_name>   Optional drive name. Default: 500GB"
    echo
}

show_error_and_exit() {
    echo "[ERROR] $1" 1>&2
    exit 1
}


# Runtime start
# Process the arguments
typeset -i arg_count=0
for arg in "$@"; do
    # Temporarily convert argument to lowercase, zsh-style
    check_arg=${arg:l}
    if [[ "${check_arg}" = "--books" || "${check_arg}" = "-b" ]]; then
        do_music=0
        ((arg_count += 1))
    elif [[ "${check_arg}" = "--music" || "${check_arg}" = "-m" ]]; then
        do_books=0
        ((arg_count += 1))
    elif [[ "${check_arg}" = "--help" || "${check_arg}" = "-h" ]]; then
        show_help
        exit 0
    else
        target_disk="${arg}"
        ((arg_count += 1))
    fi
done

# Check that the user is not excluding both jobs
[[ ${do_books} -eq 0 && ${do_music} -eq 0 ]] && show_error_and_exit "Mutually exclusive options set -- backup cannot continue"

# Set the target path based on supplied disk name (or default)
target_path="/Volumes/${target_disk}"

# Make sure the target disk is mounted
if [[ -d "${target_path}" ]]; then
    echo "Disk ${bold}${target_disk}${normal} mounted."

    # Sync document sources
    if [[ ${do_books} -eq 1 ]]; then
        echo "${bold}Locally hosted items${normal}"
        for source in "${local_sources[@]}"; do
            do_sync "${HOME}/${source}" "${target_path}"
        done

        echo "${bold}Server-hosted items${normal}"
        if [[ -d /Volumes/home ]]; then
            for source in "${home_sources[@]}"; do
                do_sync "/Volumes/home/${source}" "${target_path}"
            done
        else
            show_error_and_exit "${bold}Home${normal} server not mounted"
        fi
    fi

    # Sync music sources
    if [[ ${do_music} -eq 1 ]]; then
        echo "${bold}Server-hosted music${normal}"
        if [[ -d /Volumes/Music ]]; then
            for source in "${music_sources[@]}"; do
                do_sync "/Volumes/Music/${source}" "${target_path}/Music"
            done
        else
            show_error_and_exit "${bold}Music${normal} server not mounted"
        fi
    fi
else
    show_error_and_exit "Disk ${bold}${target_disk}${normal} is not mounted."
fi

exit 0
