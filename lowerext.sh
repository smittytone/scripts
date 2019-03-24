#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash

# Make all file extensions in the working directory lower cas
#
# Version 1.0.0

# Get all the entries in the working directory
for file in ~+/*; do
    # Only process files
    if [ -f "$file" ]; then
        # Get the extension
        extension=${file##*.}

        # Only proceed if there *is* an extension
        if ! [ -z $extension ]; then
            # Make the extension lowercase
            newextension=${extension,,}

            # No need to re-convert lowercase extensions, 
            # so check new and old version don't match
            if [ $extension != $newextension ]; then
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