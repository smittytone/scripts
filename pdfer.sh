#!/usr/bin/env bash

# Convert .docx files downloaded from Google Docs into PDFs
# Uses textutil (macOS/BSD) and cupsfilter (CUPS)
#
# Version 1.0.1

for file in ~+/*
do
    # Only process files
    if [ -f "$file" ]; then
        # Get the extension and make it uppercase
        extension=${file##*.}
        extension=${extension^^*}

        # Make sure the file's of the right type
        if [ "$extension" = "DOCX" ]; then
            # Strip off the extension
            filename=${file%.*}

            # Convert the DOCX to HTML
            textutil -convert html -output "$filename.html" "$file"

            # Convert the HTML to PDF
            cupsfilter "$filename.html" > "$filename.pdf"

            # Remove the original file and the HTML file
            rm "$file" "$filename.html" >/dev/null
        else
            # Skipping a file...
            echo -e "Skipping $file with extension $extension"
        fi
    fi
done
