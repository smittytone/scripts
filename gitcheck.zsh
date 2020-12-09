#!/bin/zsh

#
# gitcheck.zsh
#
# Display $GIT directory repos with unmerged or uncommitted changes
#
# @author    Tony Smith
# @copyright 2020, Tony Smith
# @version   1.0.0
# @license   MIT
#

target="$GIT"
list=$(/bin/ls ${target})
count=0

if cd "$target"; then
    for file in *; do
        if [[ -d "$file" ]]; then
            if cd "$file"; then
                state=""
                unmerged=$(git status)
                unmerged=$(grep 'is ahead' < <((echo -e "$unmerged")))
                if [[ -n "$unmerged" ]]; then
                    state="UNMERGED"
                fi

                if test -n "$(git status --porcelain --ignore-submodules)"; then
                    state="UNCOMMITTED"
                fi

                if [[ -n "$state" ]]; then
                    echo $file $state
                fi
                cd ..
            else
                echo ooops
            fi
        fi
    done
fi