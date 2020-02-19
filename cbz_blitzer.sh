#!/usr/bin/env bash
#
# .cbz blitzer 1.0.0
#


function processFolder {
    # Set the supplied argument as a variable
    folder="$1"

    # Make sure the supplied folder exists and IS a folder
    if ! [[ -e "$folder" || -d "$folder" ]]; then
        echo "Ignoring $folder"
        return
    fi

    # How many items in the current folder?
    count=0
    for file in "$folder"/*; do
        ((count++))
    done

    # Iterate through the current folder's items
    for file in "$folder"/*; do
        if [ -d "$file" ]; then
            # Item is a directory
            if [ $(basename -- "$file") = "__MACOSX" ]; then
                # This is an artifact from macOS-created .zips -- kill it
                rm -rf "$file"
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

                # ...get the file's name...
                filename=$(basename -- "$file")
                newfilename=${filename%.*}

                # ...make a folder in the current with the file's name...
                mkdir "$folder/$newfilename"

                # ...unpack the .cbz to the new folder...
                unzip -q "$file" -d "$folder/$newfilename"

                # ...and change the .cbz to .zip so it's not processed again
                mv "$file" "$folder/$newfilename.zip"
                # rm "$file"
            fi
        fi
    done

    # How many items NOW in the current folder?
    newcount=0
    for file in "$folder"/*; do
        ((newcount++))
    done

    # Has the file count changed? If so, reprocess it
    # NOTE Count will change when we expand the cbz files
    if [ "$newcount" -ne "$count" ]; then
        processFolder "$1"
    fi
}

# Start processing the contents of the current folder
processFolder "$PWD"