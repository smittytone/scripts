#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash

for file in *; do
    if [ -f "$file" ]; then
        # Make sure the file's of the right type
        filename="${file##*/}"
        extension=${file##*.}
        extension=${extension,,}

        if [[ "$extension" = "jpg" || "$extension" = "jpeg" || "$extension" = "png" ]]; then
            h=$(sips $file -g dpiHeight)
            s=$(grep '\s*dpiHeight: ' < <(echo -e "$h"))
            h=$(echo "$s" | cut -d: -f2)

            w=$(sips $file -g dpiWidth)
            s=$(grep '\s*dpiWidth: ' < <(echo -e "$w"))
            w=$(echo "$s" | cut -d: -f2)

            echo -n "Processing $file... was  $h x $w dpi... "
            sips $file -s dpiHeight 300 -s dpiWidth 300 --out "200-$filename" &> /dev/null

            h=$(sips "200-$filename" -g dpiHeight)
            s=$(grep '\s*dpiHeight: ' < <(echo -e "$h"))
            h=$(echo "$s" | cut -d: -f2)

            w=$(sips "200-$filename" -g dpiWidth)
            s=$(grep '\s*dpiWidth: ' < <(echo -e "$w"))
            w=$(echo "$s" | cut -d: -f2)
            echo "is $h x $w dpi"
        fi
    fi
done