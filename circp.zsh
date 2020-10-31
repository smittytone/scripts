#!/bin/zsh

#
# circp.zsh
#
# Copy a code file to a CircuitPython device with USP bootloader
#
# @author    Tony Smith
# @copyright 2020, Tony Smith
# @version   1.0.0
# @license   MIT
#

APP_NAME=$(basename $0)
APP_NAME=${APP_NAME:t}
APP_VERSION="1.0.0"
# Functions
show_help() {
    echo -e "circp $APP_VERSION\n"
    echo -e "Usage:\n"
    echo -e "  circp <file 1> <file 2> ... <file n>\n"
    echo -e "Options:\n"
    echo -e "  -h / --help   Show this help page\n"
    echo -e "Description:\n"
    echo "  Copies the specified file(s) to the CIRCUITPY drive, if mounted."
    echo "  The first file will be renamed code.py, but subsequent files will"
    echo "  be copeied unchanged. Only .py and .mpy files will be copied."
    exit 0
}

# FROM 1.0.2
show_error() {
    echo "${APP_NAME} error: $1" 1>&2
}

# Runtime start
target="/volumes/CIRCUITPY"

# Check that the drive is mounted
if ! [[ -e "$target" ]]; then
    echo "$target not mounted -- cannot continue"
    exit 1
fi

# Process the arguments
code_file=""
lib_files=()
typeset -i arg_count=0

for arg in "$@"; do
    # Temporarily convert argument to lowercase, zsh-style
    # And check for options first
    check_arg=${arg:l}
    if [[ "$check_arg" = "--help" || "$check_arg" = "-h" ]]; then
        show_help
    fi

    # The arg is not an option so check its extension to
    # see if it is a file to copy
    ext=${arg:e}
    if [[ "$ext" = "py" || "$ext" = "mpy" ]]; then
        # Only proceed for '.py' and '.mpy' files
        if [[ arg_count -eq 0 ]]; then
            # The first item is the one that will
            # become 'code.py' on the device
            code_file="$arg"
            ((arg_count += 1))
        else
            # Add a library file to the list
            lib_files+=("$arg")
        fi
    fi
done

# Bail of no files were provided
if [[ arg_count -eq 0 ]]; then
    echo "No Python files to copy"
    exit 1
fi

# Copy the primary file
echo "Copying $code_file to $target/code.py..."
cp "$code_file" "$target/code.py"

# Check if there are other files, eg. libs, to copy
if [[ ${#lib_files[@]} -gt 0 ]]; then
    for file in "$lib_files"; do
        echo "Copying $file to $target/${file:t}..."
        cp "$file" "$target"
    done
fi