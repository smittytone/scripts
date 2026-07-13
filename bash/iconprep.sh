#!/usr/bin/env bash

#
# iconprep.sh
#
# Prep macOS/watchOS/iOS Icons
#
# @shell     bash -- requires 5.0.0+
# @author    Tony Smith
# @copyright 2024, Tony Smith
# @version   1.3.0
# @license   MIT
#

# Function to show help info - keeps this out of the code
function showHelp() {
    echo -e "\nIcon Prepare\n"
    echo -e "Usage:\n  iconprep [-s path] [-d path] [-t type]\n"
    echo    "Options:"
    echo    "  -s / --source       [path]  The path of the source image. The source image should"
    echo    "                              be at least 1024x1024, and a PNG or JPG file"
    echo    "  -n / --name         [name]  The base name of output icons. Default: set by type"
    echo    "  -d / --destination  [path]  The path to the target folder. Default: desktop"
    echo    "  -t / --type         [int]   The output type: 1 - macOS app icons (Default)"
    echo    "                                               2 - macOS toolbar icons"
    echo    "                                               3 - watchOS app icons"
    echo    "                                               4 - watchOS complication icons"
    echo    "                                               5 - iOS app icons"
    echo    "                                               6 - Web app icons"
    echo    "  -h / --help                 This help screen"
    echo
}

# Set inital state values
source_image="UNSET"
dest_folder="$HOME/Desktop"
icon_type=1
arg_value=0
args=(-s -t -d)
m_a_sizes=(16 32 64 96 128 256 512 1024)
m_t_sizes=(32 64 96)
w_a_sizes=(216 196 172 100 88 87 80 58 55 48)
w_c_sizes=(224 203 182 64 58 52 50 44 40 36 32)
i_a_sizes=(40 60 58 87 76 114 80 120 180 128 192 136 152 167 1024)
s_w_sizes=(64 128)
# FROM 1.2.0
names=(macos_appicon macos_toolbar watchos_app_icon watchos_comp_icon ios_app_icon web_app_icon)
name="NONE"

# Funcions
m_a_make() {
    # Make macOS app icons
    for size in "${m_a_sizes[@]}"; do
        make "${dest_folder}/${name}_${size}.${extension}"
    done
}

m_t_make() {
    # Make macOS toolbar icons
    count=0
    filename="${source_image##*/}"
    filename="${filename%.*}"
    for size in "${m_t_sizes[@]}"; do
        sizemark=""
        if [ $count -eq 1 ]; then
            sizemark='@2x'
        fi
        if [ $count -eq 2 ]; then
            sizemark='@3x'
        fi
        make "${dest_folder}/${name}_${filename}${sizemark}.${extension}"
        ((count++))
    done
}

w_a_make() {
    # Make watcOS complication icons
    for size in "${w_a_sizes[@]}"; do
        make "${dest_folder}/${name}_${size}.${extension}"
    done
}

w_c_make() {
    # Make watcOS complication icons
    for size in "${w_c_sizes[@]}"; do
        make "${dest_folder}/${name}_${size}.${extension}"
    done
}

i_a_make() {
    # Make watcOS complication icons
    for size in "${i_a_sizes[@]}"; do
        make "${dest_folder}/${name}_${size}.${extension}"
    done
}

s_w_make() {
    # Make smittytone web site app icons
    for size in "${s_w_sizes[@]}"; do
        make "${dest_folder}/${name}_${size}.${extension}"
    done
}

make() {
    # Generic function to copy source to new file and then resize the copy
    cp "$source_image" "$1"
    sips "$1" -Z "$size" -i > /dev/null
}


# Runtime start
# Process the arguments
arg_count=0
for arg in "$@"
do
    if [[ $arg_value -gt 0 ]]; then
        # The argument should be a value (previous argument was an option)
        if [[ ${arg:0:1} = "-" ]]; then
            # Next value is an option: ie. missing value
            echo "Error -- Missing value for ${args[((arg_value - 1))]}"
            exit 1
        fi

        # Set the appropriate internal value
        case "$arg_value" in
            1)  source_image=$arg ;;
            2)  icon_type=$arg ;;
            3)  dest_folder=$arg ;;
            4)  name=$arg ;;
            *) echo "Error -- Unknown argument" exit 1 ;;
        esac

        arg_value=0
    else
        if [[ $arg = "-s" || $arg = "--source" ]]; then
            arg_value=1
        elif [[ $arg = "-t" || $arg = "--type" ]]; then
            arg_value=2
        elif [[ $arg = "-d" || $arg = "--destination" ]]; then
            arg_value=3
        elif [[ $arg = "-n" || $arg = "--name" ]]; then
            arg_value=4
        elif [[ $arg = "-h" || $arg = "--help" ]]; then
            showHelp
            exit 0
        fi
    fi

    ((arg_count++))
    if [[ $arg_count -eq $# && $arg_value -ne 0 ]]; then
        echo "Error -- Missing value for $arg"
        exit 1
    fi
done

# FROM 1.2.0
# Fix the name
if [ "$name" = "NONE" ]; then
    name=${names[(($icon_type - 1))]}
fi

# Make sure we have a source image
if [ "$source_image" != "UNSET" ]; then
    if [ -f "$source_image" ]; then
        if [ -d "$dest_folder" ] ; then
            # Get the extension and make it uppercase
            extension=${source_image##*.}
            ext_test=${extension^^*}

            # Make sure the file's of the right type
            if [[ $ext_test = "PNG" || $ext_test = "JPG" || $ext_test = "JPEG" ]]; then
                # Make the icons by type
                case "$icon_type" in
                    1)  m_a_make ;;
                    2)  m_t_make ;;
                    3)  w_a_make ;;
                    4)  w_c_make ;;
                    5)  i_a_make ;;
                    6)  s_w_make ;;
                    *) echo "Error -- Unknown icon type specified ($icon_type)" ; exit 1 ;;
                esac
            else
                echo "Source image must be a PNG or JPG. It is a $extension"
                exit 1
            fi
        else
            echo "Destination folder $dest_folder can't be found"
            exit 1
        fi
    else
        echo "Source image $source_image can't be found"
        exit 1
    fi
else
    echo "Error -- No source image set"
    exit 1
fi
