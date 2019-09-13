#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash

# Crop, pad, scale and/or reformat image files
#
# Version 5.0.0


# Function to show help info - keeps this out of the code
function showHelp() {
    echo -e "\nImage Size Adjust Utility\n"
    echo -e "Usage:\n    imagepad [-s path] [-d path] [-c padColour] [-a c crop_height crop_width] "
    echo    "             [-a p pad_height pad_width] [-r] [-f] [-k] [-h]"
    echo    "    NOTE You can selet either crop, pad or scale or all three, but actions will always"
    echo -e "         be performed in this order: pad, then crop, then scale.\n"
    echo    "Options:"
    echo    "    -s / --source      [path]                  The path to the images. Default: current working directory."
    echo    "    -d / --destination [path]                  The path to the images. Default: Downloads folder."
    echo    "    -c / --colour      [colour]                The padding colour in Hex, eg. A1B2C3. Default: FFFFFF."
    echo    "    -a / --action      [type] [height] [width] The crop/pad dimensions. Type is s (scale), c (crop) or p (pad)."
    echo    "    -r / --resolution  [dpi]                   Set the image dpi, eg. 300"
    echo    "    -f / --format      [format]                Set the image format: JPG/JPEG, PNG or TIF/TIFF"
    echo    "    -k / --keep                                Keep the source file. Without this, the source will be deleted."
    echo    "    -q / --quiet                               Silence output messages (errors excepted)."
    echo    "    -h / --help                                This help screen."
    echo
}


# Set inital state values
destPath="$HOME/Downloads"
sourcePath=~+
argType=c
padColour=FFFFFF
cropHeight=2182
cropWidth=1668
padHeight=2224
padWidth=1668
scaleHeight=$padHeight
scaleWidth=$padWidth
dpi=300
format=UNSET
formatExtension=PNG
doCrop=0
doPad=0
reformat=0
doScale=0
doRes=0
noMessages=0
deleteSource=1
argIsAValue=0
args=(-s -d -c -r -f -a -h -q -k)
supportedFormats=(png jpg jpeg tif tiff)

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
            5)  format=$arg ;;
            6)  argType=$arg ;; # Next argument is the 'type' value ('c', 'p' or 's')
            7)  if [ "$argType" = "c" ]; then
                    doCrop=1
                    cropHeight=$arg
                elif [ "$argType" = "s" ]; then
                    doScale=1
                    scaleHeight=$arg
                else
                    doPad=1
                    padHeight=$arg
                fi ;;
            8)  if [ "$argType" = "c" ]; then
                    doCrop=1
                    cropWidth=$arg
                elif [ "$argType" = "s" ]; then
                    doScale=1
                    scaleWidth=$arg
                else
                    doPad=1
                    padWidth=$arg
                fi ;;
            *) echo "Error: Unknown argument"; exit 1 ;;
        esac

        # Reset 'argIsAValue' for values 6 through 8 (ie. actions, which have extra params)
        if [[ $argIsAValue -eq 8 || $argIsAValue -lt 6 ]]; then
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
        elif [[ $arg = "-f" || $arg = "--format" ]]; then
            reformat=1
            argIsAValue=5
        elif [[ $arg = "-a" || $arg = "--action" ]]; then
            argIsAValue=6
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

# FROM 5.0.0
# Check the reformatting, if present
if [ $reformat -eq 1 ]; then
    # Make the format value lowercase
    format=${format,,}

    # Is the value valid?
    valid=0
    formatExtension=$format
    if [ $format = "jpg" ]; then
        format=jpeg
        valid=1
    elif [ $format = "jpeg" ]; then
        formatExtension=JPG
        valid=1
    elif [ $format = "tif" ]; then
        format=tiff
        formatExtension=TIFF
        valid=1
    elif [ $format = "tiff" ]; then
        valid=1
    elif [ $format = "png" ]; then
        valid=1
    fi

    if ! [ $valid -eq 1 ]; then
        echo "Invalid image format selected: $format -- exiting"
        exit 1
    fi
fi

# Output the source and destination directories
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
        extension=${extension,,}
        filename="${filename%.*}"

        # Make sure the file's of the right type
        if [[ $extension = "png" || $extension = "jpg" || $extension = "jpeg" || $extension = "tif" || $extension = "tiff" ]]; then
            if [ $noMessages -eq 0 ]; then
                echo -n "Processing $file as "
            fi

            # FROM 5.0.0
            # Set the format
            if [ $reformat -eq 1 ]; then
                # Set the new extension to match the new format before copying
                extension=$formatExtension
                cp "$file" "$destPath/$filename.$extension"

                # Now reformat
                sips "$destPath/$filename.$extension" -s format "$format" &> /dev/null
            else
                # Just copy the file
                cp "$file" "$destPath/$filename.$extension"
            fi

            if [ $noMessages -eq 0 ]; then
                echo "$destPath/$filename.$extension"
            fi

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

            # Scale the file, as requested
            if [ $doScale -eq 1 ]; then
                sips "$destPath/$filename.$extension" -z "$scaleHeight" "$scaleWidth" --padColor "$padColour" &> /dev/null
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