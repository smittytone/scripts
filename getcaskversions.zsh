#!/bin/zsh

#
# getcaskversions
#
# List current cask versions
#
# @author    Tony Smith
# @copyright 2020, Tony Smith
# @version   1.0.0
# @license   MIT
#

casks="$GIT/homebrew-smittytone/Casks"
if cd "$casks"; then
    for cask in *; do
        while IFS= read -r line; do
            version_line=$(echo $line | grep 'version')
            if [[ -n "$version_line" ]]; then
                version=$(echo "$version_line" | grep -o '[0-9].[0-9].[0-9]')
                cask_name=$(echo "$cask" | cut -d "." -s -f 1)
                echo "$cask_name is at version $version"
            fi
        done < "$cask"
    done
fi
