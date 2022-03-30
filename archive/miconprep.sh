#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash

# Prep macOS App Icons
#
# Version 1.0.1

# Function to show help info - keeps this out of the code
function showHelp() {
    echo -e "\nmacOS Icon Maker\n"
    echo -e "Usage:\n  miconprep [-p path]\n"
    echo    "Options:"
    echo    "  -p / --path   [path]   The path to the images. Default: current working directory"
    echo    "  -h / --help            This help screen"
    echo
}

# Set inital state values
path=$"HOME"/dummy.png
target="$HOME"/Desktop
argIsAValue=0
args=(-p)
sizes=(16 32 64 96 128 256 512 1024)

# Process the arguments
argCount=0
for arg in "$@"
do
    if [[ $argIsAValue -gt 0 ]]; then
        # The argument should be a value (previous argument was an option)
        if [[ ${arg:0:1} = "-" ]]; then
            # Next value is an option: ie. missing value
            echo "Error: Missing value for ${args[((argIsAValue - 1))]}"
            exit 1
        fi

        # Set the appropriate internal value
        case "$argIsAValue" in
            1)  path=$arg ;;
            *) echo "Error: Unknown argument" exit 1 ;;
        esac

        argIsAValue=0
    else
        if [[ $arg = "-p" || $arg = "--path" ]]; then
            argIsAValue=1
        elif [[ $arg = "-h" || $arg = "--help" ]]; then
            showHelp
            exit 0
        fi
    fi

    ((argCount++))
    if [[ $argCount -eq $# && $argIsAValue -ne 0 ]]; then
        echo "Error: Missing value for $arg"
        exit 1
    fi
done

if [ -f "$path" ]; then
    # Get the extension and make it uppercase for testing
    extension=${path##*.}
    ext_test=${extension^^*}

    # Make sure the file's of the right type
    if [[ $ext_test = "PNG" || $ext_test = "JPG" || $ext_test = "JPEG" ]]; then
        for size in ${sizes[@]}; do
            newname="$target"/icon_"$size.$extension"
            cp "$path" "$newname"
            sips "$newname" -Z "$size" -i > /dev/null
        done
    else
        echo "Source image must be a PNG or JPG. It is a $extension"
        exit 1
    fi
else
    echo "Source image $path can't be found"
    exit 1
fi
