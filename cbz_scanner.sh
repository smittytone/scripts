#!/usr/bin/env bash
#
# .cbz scanner 1.0.0
#


function processFolder {
    # Set the supplied argument as a variable
    currentFolder="$1"

    # Make sure the supplied folder exists and IS a folder
    if ! [[ -e "$currentFolder" || -d "$currentFolder" ]]; then
        return
    fi

    # How many items in the current folder?
    count=0
    for file in "$currentFolder"/*; do
        ((count++))
    done

    # Iterate through the current folder's items
    for file in "$currentFolder"/*; do
        if [ -d "$file" ]; then
            # Item is a directory
            foldername=$(basename -- "$file")
            if [ "$foldername" = "__MACOSX" ]; then
                # This is an artifact from macOS-created .zips -- kill it
                echo "$file"
            else
                # The folder is good to process
                processFolder "$file"
            fi
        else
            # Item is a file -- get its extension
            extension=${file##*.}
            extension=${extension,,}

            if [ "$extension" = "cbz" ]; then
                # File's extension is .cbz, so...
                echo "$file..."
            fi
        fi
    done

    # How many items NOW in the current folder?
    newcount=0
    for file in "$currentFolder"/*; do
        ((newcount++))
    done

    # Has the file count changed? If so, reprocess it
    # NOTE Count will change when we expand the cbz files
    if [ "$newcount" -ne "$count" ]; then
        processFolder "$currentFolder"
    fi
}

# Just start processing the contents of the current folder
processFolder "$PWD"
