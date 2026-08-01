#!/usr/bin/env bash

#
# cs.sh
#
# Check SHAs
#
# @author    Tony Smith
# @copyright 2026, Tony Smith
# @version   1.0.3
# @license   MIT
#


# Function to show help info - keeps this out of the code
function showHelp() {
    cat << EOF
Check SHA 1.0.3
Usage: cs [-f path] [sha]
EOF
}

# Set initial state values
argIsAValue=0
sourceFile=""
theSha=""

# Process the arguments
argCount=0
for arg in "$@"; do
    # Make argument lowercase
    arg=${arg,,}

    if [ "${argIsAValue}" -gt 0 ]; then
        # The argument should be a value (previous argument was an option)
        if [ "${arg:0:1}" = "-" ]; then
            # Next value is an option: ie. missing value
            printf "[ERROR] Missing value for %s\n" "${@[((argIsAValue - 1))]}"
            exit 1
        fi

        # Set the appropriate internal value
        case "${argIsAValue}" in
            1) sourceFile=${arg} ;;
            *) printf "[Error] Unknown argument\n"; exit 1 ;;
        esac

        argIsAValue=0
    else
        if [[ ${arg} = "-f" || ${arg} = "--file" ]]; then
            argIsAValue=1
        elif [[ ${arg} = "-h" || ${arg} = "--help" ]]; then
            showHelp
            exit 0
        else
            theSha=${arg}
        fi
    fi

    ((argCount++))
    if [[ ${argCount} -eq $# && ${argIsAValue} -ne 0 ]]; then
        printf "[Error] Missing value for %s\n" "${arg}"
        exit 1
    fi
done

# Check the supplied values
if [ -z "${theSha}" ]; then
    printf "[Error] Missing SHA\n"
    exit 1
fi

if [ -z "${sourceFile}" ]; then
    printf "[Error] No file specified\n"
    exit 1
fi

if [ ! -f "${sourceFile}" ]; then
    printf "[Error] File not found: %s\n" "${sourceFile}"
    exit 1
fi

# Get and extract the SHA
aSha=$(shasum -a 256 "${sourceFile}")
aSha=$(echo "${aSha}" | cut -d " " -f 1)

# Check the SHA
if [ "${aSha}" = "${theSha}" ]; then
    printf "SHAs match\n"
else
    printf "SHAs do not match:\n"
    printf "Specified: %s\n" "${theSha}"
    printf "From file: %s\n" "${aSha}"
fi
