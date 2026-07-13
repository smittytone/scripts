#!/bin/zsh

# Rebuild Hugo site
# Version 2.0.1

# If a command fails then the deploy stops
#set -e

# Set variables
do_deploy=1
arg_count=0
arg_is_a_value=0
source="<YOUR_WEB_SOURCE_DIR>"
destination="<YOUR_GIT_PAGES_REPO>"
msg="Latest upload @ $(date)"

# Process the arguments
for arg in "$@"
do
    if [[ $arg_is_a_value -gt 0 ]]; then
        # The argument should be a value (previous argument was an option)
        if [[ ${arg:0:1} = "-" ]]; then
            # Next value is an option: ie. missing value
            echo "Error: Missing value for ${arg[((arg_is_a_value - 1))]}"
            exit 1
        fi

        # Set the appropriate internal value
        case "$arg_is_a_value" in
            1) msg=$arg ;;
            2) source=$arg ;;
            3) destination=$arg ;;
            *) echo "Error: Unknown argument" exit 1 ;;
        esac

        arg_is_a_value=0
    else
        if [[ $arg = "-m" || $arg = "--message" ]]; then
            arg_is_a_value=1
        elif [[ $arg = "-t" || $arg = "--test" ]]; then
            do_deploy=0
        elif [[ $arg = "-s" || $arg = "--source" ]]; then
            arg_is_a_value=2
        elif [[ $arg = "-t" || $arg = "--target" ]]; then
            arg_is_a_value=3
        fi
    fi

    ((arg_count += 1))

    if [[ $arg_count -eq $# && $arg_is_a_value -ne 0 ]]; then
        echo "Error: Missing value for $arg"
        exit 1
    fi
done

# FROM 2.0.1
# Make sure Hugo is installed
which hugo > /dev/null
if [[ $? -ne 0 ]]; then
    echo "Error: Hugo not installed"
    exit 1
fi

# Move to source directory
cd "$source" || exit 1

# Zap any existing build
rm -rf public

# Run a test server or a build
if [[ $do_deploy -eq 0 ]]; then
    # Serve for testing
    hugo -D server
else
    # Build the site
    if hugo; then
        # If we're also deploying
        if [[ $do_deploy -eq 1 ]]; then
            # Copy the build site into the served repo
            cp -r public/ "$destination/"

            # Commit the changes in the served repo and push
            cd "$destination" || exit 1
            git add .
            git commit -m "$msg"
            git push origin master
        fi
    fi
fi
