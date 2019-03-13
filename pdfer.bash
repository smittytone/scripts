#!/bin/bash
# Convert .docx files downloaded from Google Docs into PDFs
for f in "$(pwd)"/*.docx
do
    # Strip the extension
    fpwe="${f%.*}"
    
    # Convert the DOCX to HTML
    textutil -convert html -output "$fpwe.html" "$f"

    # Convert the HTML to PDF
    cupsfilter "$fpwe.html" > "$fpwe.pdf"
    
    # Remove the original file and the temporary HTML file
    rm "$f" "$fpwe.html" >/dev/null
done