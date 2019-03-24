#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash

# Crop then pad image files
#
# Version 1.0.0


# Function to show help info - keeps this out of the code
function showHelp() {
    echo -e "\nImage Size Adjust Utility\n"
    echo -e "Usage: resize [-p path] [-c color] [-d c crop_height crop_width] [-d p pad_height pad_width]\n"
    echo    "Options:"
    echo    "  -p / --path   [path]   The path to the images. Default: current working directory"
    echo    "  -c / --colour [color]  The padding colour in Hex, eg. A1B2C3. Default: FFFFFF"
    echo    "  -d / --dimensions [type] [height] [width]"
    echo    "                         The crop/pad dimensions. Type is c (crop) or p (pad)."
    echo    "                         Default: c 2182 1668"
    echo    "  -h / --help            This help screen"
    echo
}


# Set inital state values
path=~+
color=FFFFFF
type=c
cheight=2182
cwidth=1668
pheight=2224
pwidth=1668
argIsAValue=0
args=(-p -c -d)

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
            1)  path=$arg ;;
            2)  color=$arg ;;
            3)  type=$arg ;;
            4)  if [ $type = "c" ]; then
                    cheight=$arg
                else
                    pheight=$arg
                fi ;;
            5)  if [ $type = "c" ]; then
                    cwidth=$arg
                else
                    pwidth=$arg
                fi ;;
            *) echo "Error: Unknown argument" exit 1 ;;
        esac

        if [[ $argIsAValue -eq 5 || $argIsAValue -lt 3 ]]; then
            argIsAValue=0
        else
            ((argIsAValue++))
        fi
    else
        if [[ $arg = "-p" || $arg = "--path" ]]; then
            argIsAValue=1
        elif [[ $arg = "-c" || $arg = "--color" ]]; then
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
for file in "$path"/*; do
    if [ -f "$file" ]; then 
        # Get the extension and make it uppercase
        extension=${file##*.}
        extension=${extension^^*}

        # Make sure the file's of the right type
        if [[ $extension = "PNG" || $extension = "JPG" || $extension = "JPEG" ]]; then
            echo "Converting $file..."
            sips "$file" -c "$cheight" "$cwidth" --padColor "$color" -i > /dev/null
            sips "$file" -p "$pheight" "$pwidth" --padColor "$color" -i > /dev/null
            
            # Increment the file count
            ((count++))
        fi
    fi
done

if [ $count -eq 1 ]; then
    echo "1 file converted"
elif [ $count -gt 1 ]; then
    echo "$count files converted"
fi