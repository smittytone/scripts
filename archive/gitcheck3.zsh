#!/usr/bin/env zsh

# gitcheck.zsh
#
# Show local git repos with unmerged or uncommitted changes
#
# @author    Tony Smith
# @copyright 2026, Tony Smith
# @version   3.0.0
# @license   MIT


# Functions
show_error_and_exit() {
    printf "\r\033[31m[ERROR]\033[39m $1\n"
    exit 1
}

show_warning() {
    printf "\r\033[33m[WARNING]\033[39m $1\n"
}

report() {
    printf "\r$1\n"
}

show_help() {
    printf "\033[1mgitcheck 3.0.0\033[0m © 2026, Tony Smith (@smittytone)\n\n"
    printf "Usage:\n  gitcheck [-f] [-b] [-a] [-l] [path/to/repo/parent path/to/repo/parent ... path/to/repo/parent]\n\n"
    printf "Options:\n"
    printf "  -f | --full       Report the status of all repos in the target directory or directories.\n"
    printf "                    Without this, only repos with changes are reported.\n"
    printf "  -b | --branch     Report the current branch of all repos in the target directory or directories.\n"
    printf "  -a | --add        Add supplied directories to the bookmark file. Currently, no de-duping takes place.\n"
    printf "  -l | --list       List currently stored bookmarks.\n\n"
    printf "Which directories gitcheck examines depends on how it is called. If no directories are passed to the\n"
    printf "command, and there are saved bookmarks, the bookmarked directories will be checked. If directories\n"
    printf "are passed to the command, these will be checked and bookmarks, if any, will be ignored. So don’t\n"
    printf "provide directories at the command line if you want bookmarks to be used.\n\n"
    printf "\033[1mIMPORTANT\033[0m Bookmarking functionality requires that jq (https://jqlang.org/) is installed on your system.\n"
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
            nogits=0
            if cd "${repo}" 2>/dev/null; then
                if [ "${show_branches}" -eq 1 ]; then
                    # FROM 1.3.1 -- determine repo current branches
                    repos+=("${repo}")
                    if [[ ${#repo} -gt ${max} ]] max=${#repo}
                    local branch=$(git branch --show-current)
                    branches+=("${branch}")
                else
                    # Set base state: if `$1` == 1, show all has been selected
                    # so make sure `$state` is not empty (this is tested later)
                    local state=""
                    if [[ "${1}" -eq 1 ]] state="[32mno"

                    # Determine repo states, but only those that are not up to date
                    local unmerged=$(git status --ignore-submodules)
                    unmerged=$(grep 'is ahead' < <((echo -e "${unmerged}")))
                    if [[ -n "${unmerged}" ]] state="[33munmerged"

                    local uncommitted=$(git status --porcelain --ignore-submodules)
                    if [[ -n "${uncommitted}" ]] state="[31muncommitted"

                    if [ -n "${state}" ]; then
                        states+=("${state}")
                        repos+=("${repo}")

                        if [[ ${#repo} -gt ${max} ]] max=${#repo}
                    fi
                fi

                cd ..
            fi

            # FROM 1.2.1 Add progress marker
            printf "."
        fi
    done

    maxes+=(${max})
}

# List bookmarks
# Parameters:
#   1. The array of bookmarks already loaded (or empty)
list_and_exit() {
    if [ "${#1[@]}" -eq 0 ]; then
        report "No bookmarks stored"
    else
        local count=1
        report "Stored bookmarks:"
        for bookmark in "${1[@]}"; do
            printf "%0d. %s\n" "${count}" "${bookmark}"
            ((count+=1))
        done
    fi

    exit 0
}

# Variables
local repos=()
local states=()
local branches=()
local show_branches=0
local maxes=()
# FROM 2.1.1
local spaces=$(printf ' %.0s' {1..20})
# FROM 2.2.0
local show_all=0
# FROM 3.0.0
local targets=()
local bookmarks=()
local nobooks=0
local dosave=0
local doshow=0
local nogits=1
local bookmark_store="${HOME}/.config/gitcheck/bookmarks.json"

# FROM 1.3.1
# Process the arguments
for arg in "$@"; do
    # Temporarily convert argument to lowercase, zsh-style
    check_arg=${arg:l}
    if [[ "${check_arg}" = "--branches" || "${check_arg}" = "-b" ]]; then
        show_branches=1
    elif [[ "${check_arg}" = "--full" || "${check_arg}" = "-f" ]]; then
        # NOTE This is only relevant to non-branch listings
        show_all=1
    elif [[ "${check_arg}" = "--add" || "${check_arg}" = "-a" ]]; then
        # Save added target(s) as bookmarks
        dosave=1
    elif [[ "${check_arg}" = "--list" || "${check_arg}" = "-l" ]]; then
        # Save added target(s) as bookmarks
        doshow=1
    elif [[ "${check_arg}" = "--help" || "${check_arg}" = "-h" ]]; then
        show_help
        exit 0
    elif [ "${arg:0:1}" = "-" ]; then
        show_error_and_exit "Unknown command ${arg}"
    else
        targets+=("${arg}")
    fi
done

# FROM 3.0.0
# Check for jq
r=$(command -v jq)
if [ "${r:0:1}" != "/" ]; then
    show_warning "JQ not installed -- bookmarking will not be available"
    nobooks=1
fi

# FROM 3.0.0
# Bookmark handling
if [ "${nobooks}" -eq 0 ]; then
    # We can access bookmarks (`jq` present). no targets were specified,
    # so load the bookmarks or make a new bookmark store
    if [ -e "${bookmark_store}" ]; then
        jq -r '.bookmarks[]' "${bookmark_store}" | while read -r bookmark; do bookmarks+=("${bookmark}"); done
    else
        show_warning "No bookmark file present -- creating one now at ${bookmark_store}"
        mkdir -p "${HOME}/.config/gitcheck/"
        echo '{"bookmarks":[]}' > ${bookmark_store}
    fi

    # Does the user just want to list bookmarks? Show them and quit
    if [ "${doshow}" -eq  1 ]; then
        list_and_exit "${bookmarks[@]}"
    fi

    # FROM 3.0.0 -- Save additional locations as bookmarks, if requested
    if [[ "${dosave}" -eq  1 && "${#targets[@]}" -gt 0 ]]; then
        cp "${HOME}/.config/gitcheck/bookmarks.json" "${HOME}/.config/gitcheck/bookmarks.bak"
        updated=$(cat "${HOME}/.config/gitcheck/bookmarks.json")
        for target in "${targets[@]}"; do
            updated=$(echo "$updated}" | jq -c --arg TARGET "${target}" '.bookmarks += [$TARGET]')
        done
        echo "${updated}" > "${HOME}/.config/gitcheck/bookmarks.json"
        report "Supplied directories added to bookmark file"
    fi

    # If no targets supplied, use the bookmarks
    if [ "${#targets[@]}" -eq 0 ]; then
        targets=("${bookmarks[@]}")
    fi
fi

# Check we have directories to examine
if [[ "${#targets[@]}" -eq 0 && ( "${nobooks}" -eq 1 || "${#bookmarks[@]}" -eq 0 ) ]]; then
    # No directories passed at the command line, and no bookmarks present
    # (these will have been added to )
    show_error_and_exit "No target directories supplied"
fi

# Check the target directories
# FROM 1.2.1 -- Add progress marker
printf "Checking"
for target in "${targets[@]}"; do
    if cd "${target}" 2>/dev/null; then
        gather "${show_all}"
    fi
done

# Output
if [ "${#repos}" -eq 0 ]; then
    if [ "${nogits}" -eq 1 ]; then
        show_warning "No repos found in the supplied directory or directories"
    else
        report "All checked local repos are up to date"
    fi
else
    # FROM 1.3.1 -- show repo current branches, or states
    local max=${maxes[1]}
    local service=1
    if [[ "$show_branches" -eq 1 ]]; then
        report "\rGit directory \033[1m${targets[${service}]}\033[0m repo current branches:${spaces}"
        for (( i = 1 ; i <= ${#repos[@]} ; i++ )); do
            if [[ "${repos[i]}" == "=" ]]; then
                ((service+=1))
                report "\nGit directory \033[1m${targets[${service}]}\033[0m repo current branches:"
                max=${maxes[${service}]}
            else
                printf '\033[1m%*s\033[0m is on \033[1m%s\033[0m\n' ${max} "${repos[i]}" "${branches[i]}"
            fi
        done
    else
        if [ "${show_all}" -eq 1 ]; then
            report "\rGit directory \033[1m${targets[${service}]}\033[0m repos:${spaces}${spaces}"
        else
            report "\rGit directory \033[1m${targets[${service}]}\033[0m repos with changes:${spaces}"
        fi

        for (( i = 1 ; i <= ${#repos[@]} ; i++ )); do
            if [[ "${repos[i]}" == "=" ]]; then
                ((service+=1))
                if [ "${show_all}" -eq 1 ]; then
                    report "\nGit directory \033[1m${targets[${service}]}\033[0m repos:"
                else
                    report "\nGit directory \033[1m${targets[${service}]}\033[0m repos with changes:"
                fi

                max=${maxes[${service}]}
            else
                printf '\033[1m%*s\033[0m has \033[1m\033%s\033[0m changes\n' ${max} "${repos[i]}" "${states[i]}"
            fi
        done
    fi
fi

exit 0
