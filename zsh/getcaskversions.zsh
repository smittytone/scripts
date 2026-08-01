#!/usr/bin/env zsh

# getcaskversions
#
# List current cask versions
#
# @author    Tony Smith
# @copyright 2026, Tony Smith
# @version   1.0.3
# @license   MIT

casks="$GH/homebrew-smittytone/Casks"
if cd "${casks}" 2>/dev/null; then
    for cask in *; do
        while IFS= read -r line; do
            version_line=$(echo ${line} | grep 'version')
            if [ -n "${version_line}" ]; then
                version=$(echo "${version_line}" | egrep -o '[0-9]+.[0-9]+.[0-9]+')
                cask_name=$(echo "${cask}" | cut -d "." -s -f 1)
                printf "Cask ${cask_name} is at version ${version}\n"
            fi
        done < "${cask}"
    done
else
    printf "[ERROR] Casks folder '${casks}' not found\n"
    exit 1
fi
