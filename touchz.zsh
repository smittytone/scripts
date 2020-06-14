#!/bin/zsh

# Make a .zsh stub file in the current directory
# Version 1.0.0

target_dir=$(pwd)
if [[ -n "$1" && ! -e "$target_dir/$1" ]]; then
    # File has been named and doesn't exist
    file_name="$1"
    if [[ "$file_name:e" != "zsh" ]]; then
        file_name="${file_name:t:r}.zsh"
    fi
else
    # The file has not been named, or the named file exists
    typeset -i file_num=1

    while [[ -e "${target_dir}/Untitled-${file_num}.zsh" ]]; do
        (( file_num += 1 ))
    done

    file_name="Untitled-${file_num}.zsh"
fi

# Create the file with stub lines
printf '%s\n' '#!/bin/zsh' '' '#' '# Version x.y.z' \
'' "APP_NAME=\"$file_name\"" > "$target_dir/$file_name" || exit 1
