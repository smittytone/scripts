#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash

# Crop then pad image files
#
# Version 1.1.0


# Function to show help info - keeps this out of the code
function showHelp() {
    echo -e "\nImage Size Adjust Utility\n"
    echo -e "IMPORTANT Run this script from the destination folder\n"
    echo -e "Usage:\n  imagepad [-p path] [-c padColour] [-d c crop_height crop_width] [-d p pad_height pad_width]"
    echo -e "  NOTE You can selet either crop, pad or both\n"
    echo    "Options:"
    echo    "  -p / --path       [path]                  The path to the images. Default: current working directory"
    echo    "  -c / --colour     [colour]                The padding colour in Hex, eg. A1B2C3. Default: FFFFFF"
    echo    "  -d / --dimensions [type] [height] [width] The crop/pad dimensions. Type is c (crop) or p (pad)."
    echo    "  -h / --help                 This help screen"
    echo
}


# Set inital state values
path=~+
argType=c
padColour=FFFFFF
cropHeight=2182
cropWidth=1668
padHeight=2224
padWidth=1668
doCrop=0
doPad=0
argIsAValue=0
args=(-p -c -d)

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
            2)  padColour=$arg ;;
            3)  argType=$arg ;;
            4)  if [[ $argType = "c" ]]; then
                    doCrop=1
                    cropHeight=$arg
                else
                    doPad=1
                    padHeight=$arg
                fi ;;
            5)  if [[ $argType = "c" ]]; then
                    doCrop=1
                    cropWidth=$arg
                else
                    doPad=1
                    padWidth=$arg
                fi ;;
            *) echo "Error: Unknown argument"; exit 1 ;;
        esac

        if [[ $argIsAValue -eq 5 || $argIsAValue -lt 3 ]]; then
            argIsAValue=0
        else
            ((argIsAValue++))
        fi
    else
        if [[ $arg = "-p" || $arg = "--path" ]]; then
            argIsAValue=1
        elif [[ $arg = "-c" || $arg = "--padColour" ]]; then
            argIsAValue=2
        elif [[ $arg = "-d" || $arg = "--dimensions" ]]; then
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

count=0
for file in "$path"/*
do
    if [ -f "$file" ]; then
        # Get the extension and make it uppercase
        extension=${file##*.}
        extension=${extension^^*}

        # Make sure the file's of the right type
        if [[ $extension = "PNG" || $extension = "JPG" || $extension = "JPEG" ]]; then
            echo "Converting $file..."
            if [ $doCrop -eq 1 ]; then
                sips "$file" -c "$cropHeight" "$cropWidth" --padColor "$padColour" -i > /dev/null
            fi

            if [ $doPad -eq 1 ]; then
                sips "$file" -p "$padHeight" "$padWidth" --padColor "$padColour" -i > /dev/null
            fi

            # Increment the file count
            ((count++))
        fi
    fi
done

if [ $count -eq 1 ]; then
    echo "1 file converted"
elif [ $count -gt 1 ]; then
    echo "$count files converted"
else
    echo "No files converted"
fi