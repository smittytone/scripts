#!/usr/bin/env bash

# Rename and number a sequence of PNG files, and convert them to JPEG
# FROM 2.0.0 -- Rename JPGs too, but omit conversion (natch); change commands
#
# Version 2.1.0


# Function to show help info - keeps this out of the code
function showHelp() {
    echo -e "\nImage Renumber Utility 2.1.0\n"
    echo -e "Usage:\n  imagenum [-p path] [-t path] [-n name] [-s start] [-d digits] [-c separator] [-k] [-q] [-h]\n"
    echo    "Options:"
    echo    "  -p / --path      [path]    The path to the source images. Default: current directory."
    echo    "  -t / --target    [path]    Where to place converted images. Default: source directory."
    echo    "  -n / --name      [name]    The name of the image sequence. Default: Untitled."
    echo    "  -s / --start     [number]  The first number in the sequence. Default: 01."
    echo    "  -d / --digits    [number]  The number of digits in the sequence number. Default: 3."
    echo    '  -c / --separator [symbol]  The symbol used to separate name from number. Default: " ".'
    echo    "  -k / --keep                Keep the source files; don\'t delete them. Default: false."
    echo    "  -q / --quiet               Silence output (errors excepted)."
    echo    "  -h / --help                This help screen."
    echo
}


# Set inital state values
start=1
digits=3
name=Untitled
path=~+
dest=""
sep=space
argIsAValue=0
args=(-p -t -n -s -d -c -k -h)
doKeep=0
verbose=1

# Process the arguments
argCount=0
for arg in "$@"
do
    if [[ $argIsAValue -gt 0 ]]; then
        # The argument should be a value (previous argument was an option)
        if [ "${arg:0:1}" = "-" ]; then
            # Next value is an option: ie. missing value
            echo "Error: Missing value for ${args[((argIsAValue - 1))]}"
            exit 1
        fi

        # Set the appropriate internal value
        case "$argIsAValue" in
            1) name=$arg ;;
            2) start=$arg ;;
            3) digits=$arg ;;
            4) sep=$arg ;;
            5) path=$arg ;;
            6) dest=$arg ;;
            *) echo "Error: Unknown argument" exit 1 ;;
        esac

        argIsAValue=0
    else
        # Make argument lowercase
        arg=${arg,,}

        if [[ $arg = "-n" || $arg = "--name" ]]; then
            argIsAValue=1
        elif [[ $arg = "-s" || $arg = "--start" ]]; then
            argIsAValue=2
        elif [[ $arg = "-d" || $arg = "--digits" ]]; then
            argIsAValue=3
        elif [[ $arg = "-c" || $arg = "--separator" ]]; then
            argIsAValue=4
        elif [[ $arg = "-p" || $arg = "--path" ]]; then
            argIsAValue=5
        elif [[ $arg = "-t" || $arg = "--target" ]]; then
            argIsAValue=6
        elif [[ $arg = "-k" || $arg = "--keep" ]]; then
            doKeep=1
        elif [[ $arg = "-q" || $arg = "--quiet" ]]; then
            verbose=0
        elif [[ $arg = "-h" || $arg = "--help" ]]; then
            showHelp
            exit 0
        else
            echo "Error: Unknown argument ($arg)"
            exit 1
        fi
    fi

    ((argCount++))
    if [[ $argCount -eq $# && $argIsAValue -ne 0 ]]; then
        echo "Error: Missing value for $arg"
        exit 1
    fi
done

# Check that the maximum file sequence number is not greater than 'digits'
fileCount=0
for file in "$path"/*
do
    if [ -f "$file" ]; then
        # Get the extension and make it uppercase
        extension=${file##*.}
        extension=${extension^^*}

        # Make sure the file's of the right type
        # FROM 2.0.0 -- include JPG and JPEG files
        if [[ "$extension" = "PNG" || "$extension" = "JPG"  || "$extension" = "JPEG" || "$extension" = "TIFF" ]]; then
            ((fileCount++))
        fi
    fi
done

if [ ${#fileCount} -gt "$digits" ]; then
    echo "[Error] Specified digits ($digits) is less than the number of digits required (${#fileCount}) - use -d to set the number of output digits"
    exit 1
fi

# FROM 2.1.0 -- implement quiet operation
if [ $verbose -eq 1 ]; then
    if [ $fileCount -eq 0 ]; then
        echo "There are no suitable files to convert in folder $path"
        exit 0
    elif [ $fileCount -eq 1 ]; then
        if [ "$extension" = "PNG" ]; then
            echo "1 PNG file in folder $path will now be converted and renumbered..."
        else
            echo "1 file in folder $path will now be renumbered..."
        fi
    else
        echo "$fileCount files in folder $path will now be renumbered..."
    fi
fi

# FROM 2.0.0 -- set the default destination
if [ -z "$dest" ]; then
    dest="$path"
    echo "DEST: $dest"
fi

count=$start
for file in "$path"/*
do
    if [ -f "$file" ]; then
        # Get the extension and make it uppercase
        extension=${file##*.}
        extension=${extension^^*}

        # Make sure the file's of the right type
        # FROM 2.0.0 -- include JPG and JPEG files
        if [[ "$extension" = "PNG" || "$extension" = "JPG"  || "$extension" = "JPEG" || "$extension" = "TIFF" ]]; then

            # Make the new file name
            value=$count
            digitCount=${#value}

            # Prefix the sequence number with zeroes
            while [ "$digitCount" -lt "$digits" ]; do
                value="0$value"
                ((digitCount++))
            done

            # Add in the separator: either one of the set strings
            # (space, underscore, under, hash, minus) or the passed-in string
            if [ "$sep" = "space" ]; then
                filename="$name $value.jpg"
            else
                case $sep in
                    hash) dep="#" ;;
                    underscore) dep="_" ;;
                    under) dep="_" ;;
                    minus) dep="-" ;;
                    *) dep=$sep ;;
                esac

                filename="$name$dep$value.jpg"
            fi

            # Copy the PNG file to the destination directory
            cp "$file" "$dest/$filename"

            # FROM 2.0.0 -- only delete the source file if permitted
            if [ $doKeep -eq 0 ]; then
                rm "$file"
            fi

            if [ $verbose -eq 1 ]; then
                echo "Converting $file to $dest/$filename..."
            fi

            # Convert the copied PNG to JPEG (compression 60%)
            # FROM 2.0.0 -- only do this if necessary
            # NOTE We've already renamed the file extension to stop sips
            #      throwing an error
            if [[ "$extension" = "PNG" || "$extension" = "TIFF" ]]; then
                sips "$dest/$filename" -s format jpeg -s formatOptions 60 > /dev/null
            fi

            # Increment the file count
            ((count++))
        fi
    fi
done

if [ $verbose -eq 1 ]; then
    ((count = count - start))
    if [ $count -eq 1 ]; then
        echo "1 file converted"
    elif [ $count -gt 1 ]; then
        echo "$count files converted"
    else
        echo "No files converted"
    fi
fi
