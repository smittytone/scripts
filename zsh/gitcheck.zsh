#!/bin/zsh

# gitcheck.zsh
#
# Display local GitHub ($GH), GitLab ($GL), etc. directory repos with unmerged or uncommitted changes
#
# @author    Tony Smith
# @copyright 2026, Tony Smith
# @version   2.0.0
# @license   MIT


show_error_and_exit() {
    echo "[ERROR] $1"
    exit 1
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
                    unmerged=$(grep 'is ahead' < <((echo -e "$unmerged")))
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
local git_dirs=("${GH}" "${GL}")
local git_dir_names=('$GH' '$GL')
local git_service_names=("GitHub" "GitLab")

# Check sources and env vars
for (( i = 1 ; i <= ${#git_dirs[@]} ; i++ )); do
    [[ -z "${git_dirs[i]}" ]] && show_error_and_exit "Environment variable ${git_dir_names[i]} not set with your local ${git_service_names[i]} directory"
    [[ ! -d "${git_dirs[i]}" ]] && show_error_and_exit "Directory referenced by environment variable ${git_dir_names[i]} does not exist"
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
    if cd "${git_dirs[i]}"; then
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
        echo -e "\nLocal repo current branches (${git_service_names[${service}]}):"
        for (( i = 1 ; i <= ${#repos[@]} ; i++ )); do
            if [[ "${repos[i]}" == "=" ]]; then 
                ((service+=1))
                echo -e "\nLocal repo current branches (${git_service_names[${service}]}):"
                max=${maxes[${service}]}
            else
                printf '%*s is on %s\n' ${max} ${repos[i]} ${branches[i]}
            fi
        done
    else
        echo -e "\nLocal repos with changes (${git_service_names[${service}]}):"
        for (( i = 1 ; i <= ${#repos[@]} ; i++ )); do
            if [[ "${repos[i]}" == "=" ]]; then 
                ((service+=1))
                echo -e "\nLocal repos with changes (${git_service_names[${service}]}):"
                max=${maxes[${service}]}
            else
                printf '%*s has %s changes\n' ${max} ${repos[i]} ${states[i]}
            fi
        done
    fi
fi

exit 0
