#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash

# Prep macOS/watchOS/iOS Icons
#
# Version 1.0.1

# Function to show help info - keeps this out of the code
function showHelp() {
    echo -e "\nIcon Maker\n"
    echo -e "Usage:\n  iconprep [-s path] [-d path] [-t type]\n"
    echo    "Options:"
    echo    "  -s / --source       [path]  The path of the source image. The source image should"
    echo    "                              be at least 1024x1024, and a PNG or JPG file"
    echo    "  -d / --destination  [path]  The path to the target folder. Default: desktop"
    echo    "  -t / --type         [int]   The output type: 1 - macOS app icons (Default)"
    echo    "                                               2 - macOS toolbar icons"
    echo    "                                               3 - watchOS app icons"
    echo    "                                               4 - watchOS complication icons"
    echo    "                                               5 - iOS app icons"
    echo    "  -h / --help                 This help screen"
    echo
}

# Set inital state values
sourceImage="UNSET"
destFolder="$HOME/Desktop"
iType=1
argIsAValue=0
args=(-s -t -d)
m_a_sizes=(16 32 64 96 128 256 512 1024)
m_t_sizes=(32 64 96)
w_a_sizes=(216 196 172 100 88 87 80 58 55 48)
w_c_sizes=(224 203 182 64 58 52 50 44 40 36 32)
i_a_sizes=(40 60 58 87 80 120 180 20 29 76 152 167 1024)

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
            1)  sourceImage=$arg ;;
            2)  iType=$arg ;;
            3)  destFolder=$arg ;;
            *) echo "Error: Unknown argument" exit 1 ;;
        esac

        argIsAValue=0
    else
        if [[ $arg = "-s" || $arg = "--source" ]]; then
            argIsAValue=1
        elif [[ $arg = "-t" || $arg = "--type" ]]; then
            argIsAValue=2
        elif [[ $arg = "-d" || $arg = "--destination" ]]; then
            argIsAValue=3
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

m_a_make() {
    # Make macOS app icons
    for size in ${m_a_sizes[@]}; do
        make "$destFolder/macos_appicon_$size.$extension"
    done
}

m_t_make() {
    # Make macOS toolbar icons
    count=0
    filename="${sourceImage##*/}"
    filename="${filename%.*}"
    for size in ${m_t_sizes[@]}; do
        sizemark=""
        if [ $count -eq 1 ]; then
            sizemark='@2x'
        fi
        if [ $count -eq 2 ]; then
            sizemark='@3x'
        fi
        make "$destFolder/macos_toolbar_$filename$sizemark.$extension"
        ((count++))
    done
}

w_a_make() {
    # Make watcOS complication icons
    for size in ${w_a_sizes[@]}; do
        make "$destFolder/watchos_app_icon_$size.$extension"
    done
}

w_c_make() {
    # Make watcOS complication icons
    for size in ${w_c_sizes[@]}; do
        make "$destFolder/watchos_comp_icon_$size.$extension"
    done
}

i_a_make() {
    # Make watcOS complication icons
    for size in ${i_a_sizes[@]}; do
        make "$destFolder/ios_app_icon_$size.$extension"
    done
}

make() {
    # Generic function to copy source to new file and then resize the copy
    cp "$sourceImage" "$1"
    sips "$1" -Z "$size" -i > /dev/null
}

# Make sure we have a source image
if [ "$sourceImage" != "UNSET" ]; then
    if [ -f "$sourceImage" ]; then
        if [ -d "$destFolder" ] ; then
            # Get the extension and make it uppercase
            extension=${sourceImage##*.}
            ext_test=${extension^^*}

            # Make sure the file's of the right type
            if [[ $ext_test = "PNG" || $ext_test = "JPG" || $ext_test = "JPEG" ]]; then
                # Make the icons by type
                case "$iType" in
                    1)  m_a_make ;;
                    2)  m_t_make ;;
                    3)  w_a_make ;;
                    4)  w_c_make ;;
                    5)  i_a_make ;;
                    *) echo "Error: Unknown icon type specified ($iType)" ; exit 1 ;;
                esac
            else
                echo "Source image must be a PNG or JPG. It is a $extension"
                exit 1
            fi
        else
            echo "Destination folder $destFolder can't be found"
            exit 1
        fi
    else
        echo "Source image $sourceImage can't be found"
        exit 1
    fi
else
    echo "Error: No source image set"
    exit 1
fi