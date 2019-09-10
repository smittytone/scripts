#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash

# Crop and/or pad image files
#
# Version 3.0.0


# Function to show help info - keeps this out of the code
function showHelp() {
    echo -e "\nImage Size Adjust Utility\n"
    echo -e "Usage:\n    imagepad [-s path] [-d path] [-c padColour] [-a c crop_height crop_width] "
    echo    "             [-a p pad_height pad_width] [-r] [-k] [-h]"
    echo    "    NOTE You can selet either crop, pad or both, but pad actions will always be"
    echo -e "         performed before crop actions\n"
    echo    "Options:"
    echo    "    -s / --source      [path]                  The path to the images. Default: Downloads folder."
    echo    "    -d / --destination [path]                  The path to the images. Default: current working directory."
    echo    "    -c / --colour      [colour]                The padding colour in Hex, eg. A1B2C3. Default: FFFFFF."
    echo    "    -a / --action      [type] [height] [width] The crop/pad dimensions. Type is c (crop) or p (pad)."
    echo    "    -r / --resolution  [dpi]                   Set the image dpi. Default: 300."
    echo    "    -k / --keep                                Keep the source file. Without this, the source will be deleted."
    echo    "    -q / --quiet                               Silence output messages (errors excepted)."
    echo    "    -h / --help                                This help screen."
    echo
}


# Set inital state values
destPath=~+
sourcePath="$HOME/Downloads"
argType=c
padColour=FFFFFF
cropHeight=2182
cropWidth=1668
padHeight=2224
padWidth=1668
dpi=300
doCrop=0
doPad=0
doRes=0
noMessages=0
deleteSource=1
argIsAValue=0
args=(-s -d -c -r -a -h -q -k)

# Process the arguments
argCount=0
for arg in "$@"; do
    if [[ $argIsAValue -gt 0 ]]; then
        # The argument should be a value (previous argument was an option)
        if [[ ${arg:0:1} = "-" ]]; then
            # Next value is an option: ie. missing value
            echo "Error: Missing value for ${args[((argIsAValue - 1))]}"
            exit 1
        fi

        # Set the appropriate internal value
        case "$argIsAValue" in
            1)  sourcePath=$arg ;;
            2)  destPath=$arg ;;
            3)  padColour=$arg ;;
            4)  dpi=$arg ;;
            5)  argType=$arg ;; # Next argument is the 'type' value ('c' or 'i')
            6)  if [[ $argType = "c" ]]; then
                    doCrop=1
                    cropHeight=$arg
                else
                    doPad=1
                    padHeight=$arg
                fi ;;
            7)  if [[ $argType = "c" ]]; then
                    doCrop=1
                    cropWidth=$arg
                else
                    doPad=1
                    padWidth=$arg
                fi ;;
            *) echo "Error: Unknown argument"; exit 1 ;;
        esac

        # Reset 'argIsAValue' for values 5 through 7 (crop and pad actionsm, which have extra params)
        if [[ $argIsAValue -eq 7 || $argIsAValue -lt 5 ]]; then
            argIsAValue=0
        else
            ((argIsAValue++))
        fi
    else
        if [[ $arg = "-s" || $arg = "--source" ]]; then
            argIsAValue=1
        elif [[ $arg = "-d" || $arg = "--destination" ]]; then
            argIsAValue=2
        elif [[ $arg = "-c" || $arg = "--colour" || $arg = "--color" ]]; then
            argIsAValue=3
        elif [[ $arg = "-r" || $arg = "--resolution" ]]; then
            doRes=1
            argIsAValue=4
        elif [[ $arg = "-a" || $arg = "--action" ]]; then
            argIsAValue=5
        elif [[ $arg = "-h" || $arg = "--help" ]]; then
            showHelp
            exit 0
        elif [[ $arg = "-q" || $arg = "--quiet" ]]; then
            noMessages=1
        elif [[ $arg = "-k" || $arg = "--keep" ]]; then
            deleteSource=0
        fi
    fi

    ((argCount++))

    if [[ $argCount -eq $# && $argIsAValue -ne 0 ]]; then
        echo "Error:  Missing value for $arg"
        exit 1
    fi
done

fileCount=0

# Check that the source directory is good; bail otherwise
if ! [ -e "$sourcePath" ]; then
    echo "Source directory $sourcePath cannot be found -- exiting"
    exit 1
fi

# Check that the destination directory is good; bail otherwise
if ! [ -e "$destPath" ]; then
    echo "Target directory $destPath cannot be found -- exiting"
    exit 1
fi

if [ $noMessages -eq 0 ]; then
    echo "Source: $sourcePath"
    echo "Target: $destPath"
fi

for file in "$sourcePath"/*
do
    if [ -f "$file" ]; then
        # Get the extension and make it uppercase
        filename="${file##*/}"
        extension=${file##*.}
        extension=${extension^^*}
        filename="${filename%.*}"

        # Make sure the file's of the right type
        if [[ $extension = "PNG" || $extension = "JPG" || $extension = "JPEG" ]]; then
            if [ $noMessages -eq 0 ]; then
                echo "Converting $file to $destPath/$filename.$extension..."
            fi

            # Copy the file from source to destination
            cp "$file" "$destPath/$filename.$extension"

            # Set the dpi
            if [ $doRes -eq 1 ]; then
                sips "$destPath/$filename.$extension" -s dpiHeight "$dpi" -s dpiWidth "$dpi" &> /dev/null
            fi

            # Pad the file, as requested
            if [ $doPad -eq 1 ]; then
                sips "$destPath/$filename.$extension" -p "$padHeight" "$padWidth" --padColor "$padColour" &> /dev/null
            fi

            # Crop the file, as requested
            if [ $doCrop -eq 1 ]; then
                sips "$destPath/$filename.$extension" -c "$cropHeight" "$cropWidth" --padColor "$padColour" &> /dev/null
            fi

            # Increment the file count
            ((fileCount++))


            # Remove the source file if requested
            if [ $deleteSource -gt 0 ]; then
                rm "$file"
            fi
        fi
    fi
done

# Present a task report
if [ $noMessages -eq 0 ]; then
    if [ $fileCount -eq 1 ]; then
        echo "1 file converted"
    elif [ $fileCount -gt 1 ]; then
        echo "$fileCount files converted"
    else
        echo "No files converted"
    fi
fi