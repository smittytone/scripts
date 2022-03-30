#!/usr/bin/env bash

#
# imageprep.sh
#
# Crop, pad, scale and/or reformat image files
#
# @author    Tony Smith
# @copyright 2020, Tony Smith
# @version   5.2.5
# @license   MIT
#


# Function to show help info - keeps this out of the code
function showHelp {
    echo -e "\nimageprep 5.2.5\n"
    echo -e "A macOS Image Adjustment Utility\n"
    echo -e "Usage:\n    imageprep [-s path] [-d path] [-c padColour] [-a s scale_height scale_width] "
    echo -e "              [-a p pad_height pad_width] [-a c crop_height crop_width] [-r] [-f] [-k] [-h]\n"
    echo    "    NOTE You can select either crop, pad or scale or all three, but actions will always"
    echo -e "         be performed in this order: pad, then crop, then scale.\n"
    echo    "Options:"
    echo    "    -s / --source      [path]                  The path to an image or a directory of images. Default: current working directory."
    echo    "    -d / --destination [path]                  The path to the images. Default: source directory."
    echo    "    -a / --action      [type] [width] [height] The crop/pad dimensions. Type is s (scale), c (crop) or p (pad)."
    echo    "    -c / --colour      [colour]                The padding colour in Hex, eg. A1B2C3. Default: FFFFFF."
    echo    "    -r / --resolution  [dpi]                   Set the image dpi, eg. 300"
    echo    "    -f / --format      [format]                Set the image format: JPG/JPEG, PNG or TIF/TIFF"
    echo    "    -k / --keep                                Keep the source file. Without this, the source will be deleted."
    echo    "    -q / --quiet                               Silence output messages (errors excepted)."
    echo    "    -h / --help                                This help screen."
    echo
}


# FROM 5.1.0
# Separarate out the code that processes a given file into a function
function processFile {
    file="$1"

    if ! [ -s "$file" ]; then
        echo "[ERROR] $file has no content -- ignoring "
        return
    fi

    # Get the extension and make it uppercase
    parseFileName "$file"

    # Make sure the file's of the right type
    if [[ $extension = "png" || $extension = "jpg" || $extension = "jpeg" || $extension = "tif" || $extension = "tiff" ]]; then
        if [ "$noMessages" -eq 0 ]; then
            echo -n "Processing $file as "
        fi

        # Copy the file before editing...
        # FROM 5.0.1 -- ...but not if source and destination match
        # FROM 5.0.3 -- Move this up so it happens first
        if [ "$file" != "$destPath/$filename.$extension" ]; then
            cp "$file" "$destPath/$filename.$extension" &> /dev/null
        fi

        # FROM 5.0.0
        # Set the format (and perform the copy)
        if [ "$reformat" -eq 1 ]; then
            # FROM 5.0.2
            # If we're converting from PNG or TIFF, perform an dpi change before converting to target format
            if [ "$doRes" -eq 1 ]; then
                doneRes=0
                if [[ $extension = "png" || $extension = "tiff" || $extension = "tif" ]]; then
                    sips "$destPath/$filename.$extension" -s dpiHeight "$dpi" -s dpiWidth "$dpi" &> /dev/null
                    doneRes=1
                fi
            fi

            # Output the new format as a new copy, then delete the old copy and set the new extension
            sips "$destPath/$filename.$extension" -s format "$format" --out "$destPath/$filename.$formatExtension" &> /dev/null
            rm "$destPath/$filename.$extension"
            extension=$formatExtension
        fi

        if [ "$noMessages" -eq 0 ]; then
            echo "$destPath/$filename.$extension"
        fi

        # Pad the file, as requested
        if [ "$doPad" -eq 1 ]; then
            sips "$destPath/$filename.$extension" -p "$padHeight" "$padWidth" --padColor "$padColour" &> /dev/null
        fi

        # Crop the file, as requested
        if [ "$doCrop" -eq 1 ]; then
            sips "$destPath/$filename.$extension" -c "$cropHeight" "$cropWidth" --padColor "$padColour" &> /dev/null
        fi

        # Scale the file, as requested
        if [ "$doScale" -eq 1 ]; then
            sips "$destPath/$filename.$extension" -z "$scaleHeight" "$scaleWidth" --padColor "$padColour" &> /dev/null
        fi

        # Set the dpi
        if [[ "$doRes" -eq 1 && "$doneRes" -eq 0 ]]; then
            if [[ "$extension" = "jpg" || "$extension" = "jpeg" ]]; then
                # sips does not apply dpi settings to JPEGs (why???) so if the target image is a JPEG,
                # convert it to PNG, apply the dpi settings and then convert it back again.
                sips "$destPath/$filename.$extension" -s format png --out "$destPath/$filename-sipstmp.png" &> /dev/null
                sips "$destPath/$filename-sipstmp.png" -s dpiHeight "$dpi" -s dpiWidth "$dpi" &> /dev/null
                sips "$destPath/$filename-sipstmp.png" -s format jpeg --out "$destPath/$filename.$extension" &> /dev/null
                rm "$destPath/$filename-sipstmp.png"
            else
                sips "$destPath/$filename.$extension" -s dpiHeight "$dpi" -s dpiWidth "$dpi" &> /dev/null
            fi
        fi

        # Increment the file count
        ((fileCount++))

        # Remove the source file if requested
        if [ "$deleteSource" -gt 0 ]; then
            rm "$file"
        fi
    fi
}


function parseFileName {
    filename="${1##*/}"
    extension=${1##*.}
    extension=${extension,,}
    filename="${filename%.*}"
}


# Set inital state values
sourcePath=~+
destPath="DEFAULT"
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
formatExtension=png
doCrop=0
doPad=0
reformat=0
doScale=0
doRes=0
doneRes=0
noMessages=0
deleteSource=1
argIsAValue=0
args=(-s -d -c -r -f -a -h -q -k)

# Process the arguments
argCount=0
for arg in "$@"; do
    if [[ "$argIsAValue" -gt 0 ]]; then
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
                    cropWidth=$arg
                elif [ "$argType" = "s" ]; then
                    doScale=1
                    scaleWidth=$arg
                else
                    doPad=1
                    padWidth=$arg
                fi ;;
            8)  if [ "$argType" = "c" ]; then
                    doCrop=1
                    cropHeight=$arg
                elif [ "$argType" = "s" ]; then
                    doScale=1
                    scaleHeight=$arg
                else
                    doPad=1
                    padHeight=$arg
                fi ;;
            *) echo "Error: Unknown argument"; exit 1 ;;
        esac

        # Reset 'argIsAValue' for values 6 through 8 (ie. actions, which have extra params)
        if [[ "$argIsAValue" -eq 8 || "$argIsAValue" -lt 6 ]]; then
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
        else
            echo "Error: Unknown option $arg"
            exit 1
        fi
    fi

    ((argCount++))

    if [[ "$argCount" -eq $# && "$argIsAValue" -ne 0 ]]; then
        echo "Error: Missing value for $arg"
        exit 1
    fi
done

fileCount=0

# Check that the source directory is good; bail otherwise
if ! [ -e "$sourcePath" ]; then
    echo "Source directory $sourcePath cannot be found -- exiting"
    exit 1
fi

# FROM 5.2.1
# If destination not set, use the source
if [ "$destPath" = "DEFAULT" ]; then
    destPath="$sourcePath"
fi

# Check that the destination directory is good; bail otherwise
if ! [ -e "$destPath" ]; then
    echo "Target directory $destPath cannot be found -- exiting"
    exit 1
fi

# FROM 5.0.0
# Check the reformatting, if present
if [ "$reformat" -eq 1 ]; then
    # Make the format value lowercase
    format=${format,,}

    # Is the value valid?
    valid=0
    formatExtension=$format
    if [ "$format" = "jpg" ]; then
        format=jpeg
        valid=1
    elif [ "$format" = "jpeg" ]; then
        formatExtension=jpg
        valid=1
    elif [ "$format" = "tif" ]; then
        format=tiff
        formatExtension=tiff
        valid=1
    elif [ "$format" = "tiff" ]; then
        valid=1
    elif [ "$format" = "png" ]; then
        valid=1
    fi

    if ! [ $valid -eq 1 ]; then
        echo "Invalid image format selected: $format -- exiting"
        exit 1
    fi
fi

# Output the source and destination directories
if [ "$noMessages" -eq 0 ]; then
    echo "Source: $(realpath $sourcePath)"
    echo "Target: $(realpath $destPath)"
    if [ $doRes -eq 1 ]; then
        echo "New DPI: $dpi"
    fi
fi

# FROM 5.1.4
# Auto-enable 'keep files' if the source and destination are the same
if [ "$sourcePath" = "$destPath" ]; then
    deleteSource=0
fi

# From 5.2.4
destPath=$(realpath $destPath)

# FROM 5.1.0
# Check for a single input file
if [ -f "$sourcePath" ]; then
    # Process the single input file
    processFile "$sourcePath"
elif [ -d "$sourcePath" ]; then
    # Process the contents of the supplied directory
    for file in "$sourcePath"/*; do
        if [ -f "$file" ]; then
            processFile "$file"
        fi
    done
else
    echo "[ERROR] $sourcePath is not a valid directory -- ignoring "
fi

# Present a task report, if requested
if [ "$noMessages" -eq 0 ]; then
    if [ $fileCount -eq 1 ]; then
        echo "1 file converted"
    elif [ $fileCount -gt 1 ]; then
        echo "$fileCount files converted"
    else
        echo "No files converted"
    fi
fi
