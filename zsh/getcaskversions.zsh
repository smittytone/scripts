#!/bin/zsh


# getcaskversions
#
# List current cask versions
#
# @author    Tony Smith
# @copyright 2021, Tony Smith
# @version   1.0.2
# @license   MIT


casks="$GIT/homebrew-smittytone/Casks"
if cd "$casks"; then
    for cask in *; do
        while IFS= read -r line; do
            version_line=$(echo $line | grep 'version')
            if [[ -n "$version_line" ]]; then
                version=$(echo "$version_line" | egrep -o '[0-9]+.[0-9]+.[0-9]+')
                cask_name=$(echo "$cask" | cut -d "." -s -f 1)
                echo "$cask_name is at version $version"
            fi
        done < "$cask"
    done
else
    echo "ERROR -- Casks folder '${casks}' not found"
    exit 1
fi
