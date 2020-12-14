#!/bin/zsh

#
# gitcheck.zsh
#
# Display $GIT directory repos with unmerged or uncommitted changes
#
# @author    Tony Smith
# @copyright 2020, Tony Smith
# @version   1.0.1
# @license   MIT
#

list=$(/bin/ls "$GIT")
max=0
output=0

if cd "$GIT"; then
    # Get the longest file name
    for file in *; do
        if [[ ${#file} -gt $max ]]; then
            max=${#file}
        fi
    done

    # Process the files
    for file in *; do
        if [[ -d "$file" ]]; then
            if cd "$file"; then
                local state=""

                unmerged=$(git status)
                unmerged=$(grep 'is ahead' < <((echo -e "$unmerged")))
                if [[ -n "$unmerged" ]]; then
                    state="unmerged changes"
                fi

                uncommitted=$(git status --porcelain --ignore-submodules)
                if [[ -n "$uncommitted" ]]; then
                    state="uncommitted changes"
                fi

                if [[ -n "$state" ]]; then
                    awk '{ printf "%-*s %-50s\n", $1, $2, $3}' <((echo -e "$max $file $state"))
                    ((output+=1))
                fi

                cd ..
            fi
        fi
    done
fi

if [[ $output -eq 0 ]]; then
    echo "All repos up to date"
fi