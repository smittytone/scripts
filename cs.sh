#!/usr/bin/env bash

# Check SHAs
#
# Version 1.0.0

# Function to show help info - keeps this out of the code
function showHelp() {
    echo -e "\nCheck SHA 1.0.0\n"
    echo -e "Usage:\n  cs [-f path] [sha]\n"
}

# Set inital state values
argIsAValue=0
sourceFile=""
theSha=""

# Process the arguments
argCount=0
for arg in "$@"; do
    # Make argument lowercase
    arg=${arg,,}

    if [[ $argIsAValue -gt 0 ]]; then
        # The argument should be a value (previous argument was an option)
        if [[ ${arg:0:1} = "-" ]]; then
            # Next value is an option: ie. missing value
            echo "Error: Missing value for ${args[((argIsAValue - 1))]}"
            exit 1
        fi

        # Set the appropriate internal value
        case "$argIsAValue" in
            1) sourceFile=$arg ;;
            *) echo "[Error] Unknown argument" exit 1 ;;
        esac

        argIsAValue=0
    else
        if [[ $arg = "-f" || $arg = "--file" ]]; then
            argIsAValue=1
        elif [[ $arg = "-h" || $arg = "--help" ]]; then
            showHelp
            exit 0
        else
            theSha=$arg
        fi
    fi

    ((argCount++))
    if [[ $argCount -eq $# && $argIsAValue -ne 0 ]]; then
        echo "[Error] Missing value for $arg"
        exit 1
    fi
done

# Check the supplied values
if [ -z "$theSha" ]; then
    echo "[Error] Missing SHA"
    exit 1
fi

if [ -z "$sourceFile" ]; then
    echo "[Error] No file specified"
    exit 1
fi

if [ ! -f "$sourceFile" ]; then
    echo "[Error] Specified file not found"
    exit 1
fi

# Get and extract the SHA
aSha=$(shasum -a 256 "$sourceFile")
aSha=$(echo "$aSha" | cut -d " " -f 1)

# Check the SHA
if [ "$aSha" = "$theSha" ]; then
    echo "SHAs match"
else
    echo "SHAs do not match:"
    echo "Specified: $theSha"
    echo "From file: $aSha"
fi
