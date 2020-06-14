#!/bin/zsh

# Make a .md file in the current directory
# Version 1.0.0

target_dir=$(pwd)
if [[ -n "$1" && ! -e "$target_dir/$1" ]]; then
    # File has been named and doesn't exist
    file_name="$1"
    if [[ "$file_name:e" != "md" ]]; then
        file_name="${file_name:t:r}.md"
    fi
else
    # The file has not been named, or the named file exists
    typeset -i file_num=1

    while [[ -e "${target_dir}/Untitled-${file_num}.md" ]]; do
        (( file_num += 1 ))
    done

    file_name="Untitled-${file_num}.md"
fi

touch "$target_dir/$file_name" || exit 1
