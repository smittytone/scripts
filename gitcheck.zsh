#!/bin/zsh

# gitcheck.zsh
#
# Display $GIT directory repos with unmerged or uncommitted changes
#
# @author    Tony Smith
# @copyright 2021, Tony Smith
# @version   1.1.0
# @license   MIT


local max=0
local output=0
local repos=()
local states=()

if [[ -z "$GIT" ]]; then
    echo 'Environment variable "$GIT" not set with your Git directory'
    exit 1
fi

if [[ ! -d "$GIT" ]]; then
    echo 'Directory referenced by environment variable "$GIT" does not exist'
    exit 1
fi

if cd "$GIT"; then
    # Process the files
    for repo in *; do
        if [[ -d "$repo" && -d "$repo/.git" ]]; then
            if cd "$repo"; then
                local state=""
                local unmerged=$(git status)
                unmerged=$(grep 'is ahead' < <((echo -e "$unmerged")))
                if [[ -n "$unmerged" ]]; then
                    state="unmerged changes"
                fi

                local uncommitted=$(git status --porcelain --ignore-submodules)
                if [[ -n "$uncommitted" ]]; then
                    state="uncommitted changes"
                fi

                if [[ -n "$state" ]]; then
                    states+=("$state")
                    repos+=("$repo")
                    if [[ ${#repo} -gt $max ]] max=${#repo}
                    output=1
                fi

                cd ..
            fi
        fi
    done
fi

if [[ $output -eq 0 ]]; then
    echo "All repos up to date"
else
    echo "Repos with changes:"
    for (( i = 1 ; i <= ${#repos[@]} ; i++ )); do
        printf '%*s has %s\n' $max ${repos[i]} ${states[i]}
    done
fi

exit 0