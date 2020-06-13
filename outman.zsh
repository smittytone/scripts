#!/bin/zsh

# Output a man page to a text file
# Version 1.0.2

APP_NAME=$(basename $0)
APP_NAME=${APP_NAME:t}
APP_VERSION="1.0.2"

# Functions
function show_help {
    echo -e "outman.zsh $APP_VERSION\n"
    echo -e "Usage:\n"
    echo -e "  outman.zsh <man_page> <text_file> ... <man_page> <text_file>\n"
    echo -e "Options:\n"
    echo -e "  -h / --help   Show this help page\n"
    echo -e "Description:\n"
    echo "  Each man page must ba accompanied by a target text file, or the script"
    echo "  will not continue and no files will be generated. If the path to the "
    echo "  target file does not exist, it will be created if permissions allow."
    echo "  If no file extension is provided for the target, '.txt' will be added."
    exit 0
}

# FROM 1.0.2
function show_error {
    echo "${APP_NAME} error: $1" 1>&2
}

# Runtime start
# Process the arguments
typeset -i is_source=1
sources=()
targets=()
for arg in "$@"; do
    test_arg=${arg:l}
    if [[ $test_arg = "-h" || $test_arg = "--help" ]]; then
        show_help
        exit 0
    fi

    # Add the source and target arguments to the arrays
    if [[ $is_source -eq 1 ]]; then
        is_source=0
        sources+=($arg)
    else
        is_source=1
        targets+=($arg)
    fi
done

# Check that source and target counts match
if [[ ${#sources} -ne ${#targets} ]]; then
    echo "At least one specified man page has no text file target -- cannot continue "
    exit 1
fi

# Specify 'target_count' as an integer
typeset -i target_count
target_count=0
for a_source in $sources; do
    # Increase the target array index counter
    ((target_count++))

    # Get the man page name from the source
    man_page=$(man "$a_source" 2>&1)

    # Check that there IS a man page for the entry
    if [[ $? -eq 0 ]]; then
        # Get the target that matches the current source
        a_target=${targets[$target_count]}

        # Check the path exists
        file_path=$a_target:h
        if [[ ! -e "$file_path" ]]; then
            if mkdir -p "$file_path"; then
                echo "[INFO] Path '$file_path' created"
            else
                show_error "Could not create path '$file_paths'"
                continue
            fi
        fi

        # Get the file name, zsh style, and check it's not null
        # If it is, append '.txt' to the target
        file_extension=$a_target:t:e
        if [[ -z "$file_extension" ]]; then
            a_target="$a_target.txt"
        fi

        # Output the man page to the text file
        echo "$man_page" | col -b  > "$a_target"
    else
        show_error "'$a_source' is not a valid man page"
    fi
done
