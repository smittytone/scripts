#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash

# Rename and number a sequence of PNG files, and convert them to JPEG
#
# Version 1.0.0


# Function to show help info - keeps this out of the code
function showHelp() {
    echo -e "\nImage Renumber Utility\n"
    echo -e "Usage: renum [-n] [name] [-s] start\n"
    echo    "Options:"
    echo    "  -n / --name      <bookname> The name of the image sequence. Default: Untitled"
    echo    "  -s / --start     <number>   The first number in the sequence. Default: 01"
    echo    "  -d / --digits    <number>   The number of digits in the sequence number. Default: 2"
    echo    '  -c / --separator <symbol>   The symbol used to separate name from number. Default: " "'
    echo
}


# Set inital state values
start=1
digits=2
name=Untitled
sep=space
argIsAValue=0
args=(-n -s -d -c)

# Process the arguments
argCount=0
for arg in $@; do
    if [[ $argIsAValue -gt 0 ]]; then
        # The argument should be a value (previous argument was an option)
        if [ ${arg:0:1} = "-" ]; then
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
            *) echo "Error: Unknown argument" exit 1 ;;
        esac

        argIsAValue=0
    else
        if [[ $arg = "-n" || $arg = "--name" ]]; then
        argIsAValue=1
        elif [[ $arg = "-s" || $arg = "--start" ]]; then
            argIsAValue=2
        elif [[ $arg = "-d" || $arg = "--digits" ]]; then
            argIsAValue=3
        elif [[ $arg = "-c" || $arg = "--separator" ]]; then
            argIsAValue=4
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

# Only look for PNG files in the Downloads folder
source=~/Downloads/*.*
count=$start

# Check that the maximum file sequence number is not greater than 'digits'
fileCount=$start
for file in $source; do
    # Get the extension and make it uppercase
    extension=${file##*.}
    extension=${extension^^*}

    # Make sure the file's of the right type
    if [ $extension = "PNG" ]; then
        ((fileCount++))
    fi
done

if [ ${#fileCount} -gt $digits ]; then
    echo "Error: Specified digits ($digits) is less than the number of digits required (${#fileCount})"
    exit 1
fi

for file in $source; do
    # Get the extension and make it uppercase
    extension=${file##*.}
    extension=${extension^^*}

    # Make sure the file's of the right type
    if [ $extension = "PNG" ]; then
        
        # Make the new file name 
        value=$count
        digitCount=${#value}

        # Prefix the sequence number with zeroes
        while [ $digitCount -lt $digits ]; do
            value="0$value"
            ((digitCount++))
        done

        # Add in the separator: either one of the set strings
        # (space, underscore, under, hash, minus) or the passed-in string
        if [ $sep = "space" ]; then
            filename=~+/"$name $value.jpg"
        else
            case $sep in
                hash) dep="#" ;;
                underscore) dep="_" ;;
                under) dep="_" ;;
                minus) dep="-" ;;
                *) dep=$sep ;;
            esac

            filename=~+/"$name$dep$value.jpg"
        fi

        # Copy the PNG file to the working directory
        cp "$file" "$filename"

        # Convert the copied PNG to JPEG
        # NOTE We've already renamed the file extension to stop sips
        #      throwing an error
        echo "Converting $file to $filename..."
        sips "$filename" -s format jpeg > /dev/null

        # Increment the file count
        ((count++))
    #else
        # Skipping a file...
        #echo "Skipping $file (extension $extension)"
    fi
done