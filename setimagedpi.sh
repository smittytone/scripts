#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash

for file in *
do
    if [ -f "$file" ]; then
        # Make sure the file's of the right type
        sips "$file" -s dpiHeight 300 -s dpiWidth 300 &> /dev/null
    fi
done