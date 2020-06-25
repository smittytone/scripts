#!/usr/bin/env bash

#
# lowerext.sh
#
# Make all file extensions in the working directory lower case
#
# @author    Tony Smith
# @copyright 2019-20, Tony Smith
# @version   1.0.1
# @license   MIT
#


# Get all the entries in the working directory
for file in ~+/*; do
    # Only process files
    if [ -f "$file" ]; then
        # Get the extension
        extension=${file##*.}

        # Only proceed if there *is* an extension
        if [ -n "$extension" ]; then
            # Make the extension lowercase
            newextension=${extension,,}

            # No need to re-convert lowercase extensions,
            # so check new and old version don't match
            if [ "$extension" != "$newextension" ]; then
                # Get the filename and add back the extension
                newfile=${file%.*}
                newfile="$newfile.$newextension"

                # Move the file
                mv "$file" "$newfile"
                echo "Processed $file to $newfile"
            fi
        fi
    fi
done
