#!/bin/zsh

# gitcheck.zsh
#
# Display $GIT directory repos with unmerged or uncommitted changes
#
# @author    Tony Smith
# @copyright 2021, Tony Smith
# @version   1.3.0
# @license   MIT


local max=0
local repos=()
local states=()
local branches=()
local show_branches=0

if [[ -z "$GIT" ]]; then
    echo 'Environment variable "$GIT" not set with your Git directory'
    exit 1
fi

if [[ ! -d "$GIT" ]]; then
    echo 'Directory referenced by environment variable "$GIT" does not exist'
    exit 1
fi

# FROM 1.3.1
# Process the arguments
for arg in "$@"; do
    # Temporarily convert argument to lowercase, zsh-style
    check_arg=${arg:l}
    if [[ "$check_arg" = "--branches" || "$check_arg" = "-b" ]]; then
        show_branches=1
    fi
done

# FROM 1.2.1 -- Add progress marker
echo -n "Checking"
if cd "$GIT"; then
    # Process the files
    for repo in *; do
        if [[ -d "$repo" && -d "$repo/.git" ]]; then
            if cd "$repo"; then
                local state=""
                if [[ "$show_branches" -eq 1 ]]; then
                    # FROM 1.3.1 -- determine repo current branches
                    repos+=("$repo")
                    if [[ ${#repo} -gt $max ]] max=${#repo}
                    local branch=$(git branch --show-current)
                    branches+=("$branch")
                else
                    # Determine repo states, but only those that are not up to date
                    local unmerged=$(git status)
                    unmerged=$(grep 'is ahead' < <((echo -e "$unmerged")))
                    if [[ -n "$unmerged" ]]; then
                        state="unmerged"
                    fi

                    local uncommitted=$(git status --porcelain --ignore-submodules)
                    if [[ -n "$uncommitted" ]]; then
                        state="uncommitted"
                    fi

                    if [[ -n "$state" ]]; then
                        states+=("$state")
                        repos+=("$repo")

                        if [[ ${#repo} -gt $max ]] max=${#repo}
                    fi
                fi

                cd ..
            fi

            # FROM 1.2.1 Add progress marker
            echo -n "."
        fi
    done
fi

if [[ ${#repos} -eq 0 ]]; then
    echo -e "\nAll repos up to date"
else
    # FROM 1.3.1 -- show repo current branches, or states
    if [[ "$show_branches" -eq 1 ]]; then
        echo -e "\nRepo current branches:"
        for (( i = 1 ; i <= ${#repos[@]} ; i++ )); do
            printf '%*s is on %s\n' $max ${repos[i]} ${branches[i]}
        done
    else
        echo -e "\nRepos with changes:"
        for (( i = 1 ; i <= ${#repos[@]} ; i++ )); do
            printf '%*s has %s changes\n' $max ${repos[i]} ${states[i]}
        done
    fi
fi

exit 0