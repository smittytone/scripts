#!/bin/zsh

# cppy.zsh
#
# Copy a code file to a CircuitPython device with UF2 bootloader
#
# @author    Tony Smith
# @copyright 2021, Tony Smith
# @version   1.0.3
# @license   MIT


APP_NAME=$(basename $0)
APP_NAME=${APP_NAME:t}
APP_VERSION="1.0.3"

# Functions
show_help() {
    echo -e "cppy $APP_VERSION\n"
    echo -e "Usage:\n"
    echo -e "  cppy <file 1> <file 2> ... <file n>\n"
    echo -e "Options:\n"
    echo -e "  -h / --help   Show this help page\n"
    echo -e "Description:\n"
    echo    "  Copies the specified file(s) to the CIRCUITPY drive, if mounted."
    echo    "  The first file will be renamed 'code.py', but subsequent files will"
    echo -e "  be copied unchanged. Only .py and .mpy files will be copied.\n"
    exit 0
}

# FROM 1.0.2
show_error() {
    echo "${APP_NAME} error: $1" 1>&2
    exit 1
}

# Runtime start
local target="/volumes/CIRCUITPY"

# Process the arguments
local code_file=""
local lib_files=()
typeset -i arg_count=0

for arg in "$@"; do
    # Temporarily convert argument to lowercase, zsh-style
    # And check for options first
    local check_arg=${arg:l}
    if [[ "$check_arg" = "--help" || "$check_arg" = "-h" ]]; then
        show_help
        exit 0
    fi

    # The arg is not an option so check its extension to
    # see if it is a file to copy
    local ext=${arg:e}
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

# Check that the drive is mounted
if ! [[ -e "$target" ]]; then
    show_error "$target not mounted -- cannot continue"
fi

# Bail if no files were provided
if [[ arg_count -eq 0 ]]; then
    show_error "No Python files to copy -- cannot continue"
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