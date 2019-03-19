#!/bin/bash

# Convert .docx files downloaded from Google Docs into PDFs
# Uses textutil (macOS/BSD) and cupsfilter (CUPS)

for file in "$(pwd)"/*
do
    # Get the extension and make it lowercase
    ext="${file##*.}"
    ext=$(echo "$ext" | tr 'A-Z' 'a-z')

    # Make sure the file's of the right type
    if [ $ext = "docx" ]; then
        # Strip off the extension
        fname="${file%.*}"
        
        # Convert the DOCX to HTML
        textutil -convert html -output "$fname.html" "$file"

        # Convert the HTML to PDF
        cupsfilter "$fname.html" > "$fname.pdf"
        
        # Remove the original file and the HTML file
        rm "$file" "$fname.html" >/dev/null
    else
        # Skipping a file...
        echo -e "Skipping "$file
    fi
done
