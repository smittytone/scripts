#!/bin/bash

# Convert .docx files downloaded from Google Docs into PDFs
# Uses textutil (macOS/BSD) and cupsfilter (CUPS)

for f in "$(pwd)"/*
do
    # Get the extension and make it lowercase
    ex="${f##*.}"
    ex=$(echo "$ex" | tr 'A-Z' 'a-z')

    # Make sure the file's of the right type
    if [ $ex = "docx" ]; then
        # Strip the extension
        fpwe="${f%.*}"
        
        # Convert the DOCX to HTML
        textutil -convert html -output "$fpwe.html" "$f"

        # Convert the HTML to PDF
        cupsfilter "$fpwe.html" > "$fpwe.pdf"
        
        # Remove the original file and the temporary HTML file
        rm "$f" "$fpwe.html" >/dev/null
    else
        # Skipping a file...
        echo -e "Skipping "$f
    fi
done
