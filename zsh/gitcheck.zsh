#!/bin/zsh

# gitcheck.zsh
#
# Display local GitHub ($GH), GitLab ($GL), etc. directory repos with unmerged or uncommitted changes
#
# @author    Tony Smith
# @copyright 2026, Tony Smith
# @version   2.1.0
# @license   MIT


##################################################################
#                     USER-DEFINED VARIABLES                     #
##################################################################
#
# Update the following array variables for your specific needs.
# They are currently populated with example values.
#
# Remember, shell script array elements are separated by spaces only,
# not commas!
#
# A mandatory array of paths for the directory or directories holding your repos.
local git_dirs=("${HOME}/GitHub\ Folder" "${HOME}/GitLab\ Folder" "${HOME}/Codeberg\ Folder")
# An optional array of the git service names associated with each of the directories listed above. This is used for reporting only.
local git_service_names=("GitHub" "GitLab" "CodeBerg")


# Functions
show_error_and_exit() {
    echo "\033[31m[ERROR]\033[39m $1"
    exit 1
}

show_warning() {
    echo "\033[31m[WARNING]\033[39m $1"
}

gather() {
    local max=0

    # Add spacers between services
    if [[ ${#repos} -gt 0 ]]; then
        repos+=("=")
        states+=("=")
        branches+=("=")
    fi

    # Process the files
    for repo in *; do
        if [[ -d "${repo}" && -d "${repo}/.git" ]]; then
            if cd "${repo}"; then
                local state=""
                if [[ "$show_branches" -eq 1 ]]; then
                    # FROM 1.3.1 -- determine repo current branches
                    repos+=("$repo")
                    if [[ ${#repo} -gt ${max} ]] max=${#repo}
                    local branch=$(git branch --show-current)
                    branches+=("${branch}")
                else
                    # Determine repo states, but only those that are not up to date
                    local unmerged=$(git status --ignore-submodules)
                    unmerged=$(grep 'is ahead' < <((echo -e "${unmerged}")))
                    [[ -n "${unmerged}" ]] && state="unmerged"

                    local uncommitted=$(git status --porcelain --ignore-submodules)
                    [[ -n "${uncommitted}" ]] && state="uncommitted"

                    if [[ -n "${state}" ]]; then
                        states+=("${state}")
                        repos+=("${repo}")

                        if [[ ${#repo} -gt ${max} ]] max=${#repo}
                    fi
                fi

                cd ..
            fi

            # FROM 1.2.1 Add progress marker
            echo -n "."
        fi
    done

    maxes+=(${max})
}

# Variables
local repos=()
local states=()
local branches=()
local show_branches=0
local maxes=()

# Check source directories
[ ${#git_dirs} -eq 0 ] && show_error_and_exit 'No git directories defined. Update the script to add them to the `git_dirs` array'
for (( i = 1 ; i <= ${#git_dirs[@]} ; i++ )); do
    [[ ! -d "${git_dirs[i]}" ]] && show_error_and_exit "Directory ${git_dirs[i]} does not exist"
done

# FROM 1.3.1
# Process the arguments
for arg in "$@"; do
    # Temporarily convert argument to lowercase, zsh-style
    check_arg=${arg:l}
    if [[ "${check_arg}" = "--branches" || "${check_arg}" = "-b" ]]; then
        show_branches=1
    else
        show_error_and_exit "Unknown command ${arg}"
    fi
done

# FROM 1.2.1 -- Add progress marker
echo -n "Checking"
for (( i = 1 ; i <= ${#git_dirs[@]} ; i++ )); do
    # FROM 2.0.1 -- Don't display missing dirs
    if cd "${git_dirs[i]}" 2>/dev/null; then
        gather
    fi
done

if [[ ${#repos} -eq 0 ]]; then
    echo -e "\nAll local repos up to date"
else
    # FROM 1.3.1 -- show repo current branches, or states
    local max=${maxes[1]}
    local service=1
    if [[ "$show_branches" -eq 1 ]]; then
        printf "\nLocal \033[1m${git_service_names[${service}]}\033[0m repo current branches:\n"
        for (( i = 1 ; i <= ${#repos[@]} ; i++ )); do
            if [[ "${repos[i]}" == "=" ]]; then
                ((service+=1))
                printf "\nLocal \033[1m${git_service_names[${service}]}\033[0m repo current branches:\n"
                max=${maxes[${service}]}
            else
                printf '\033[1m%*s\033[0m is on \033[1m%s\033[0m\n' ${max} "${repos[i]}" "${branches[i]}"
            fi
        done
    else
        printf "\nLocal \033[1m${git_service_names[${service}]}\033[0m repos with changes:\n"
        for (( i = 1 ; i <= ${#repos[@]} ; i++ )); do
            if [[ "${repos[i]}" == "=" ]]; then
                ((service+=1))
                printf "\nLocal \033[1m${git_service_names[${service}]}\033[0m repos with changes:\n"
                max=${maxes[${service}]}
            else
                printf '\033[1m%*s\033[0m has \033[1m%s\033[0m changes\n' ${max} "${repos[i]}" "${states[i]}"
            fi
        done
    fi
fi

exit 0
