#!/bin/zsh
# Split every image in a folder down the middle (vertical cut) into
# left and right halves, using macOS' sips.
#
# Usage: split_halves.sh [source_dir] [output_dir]

src="${1:-/Users/smitty/Downloads/image-done}"
out="${2:-$src/split}"

mkdir -p "$out"
setopt null_glob nocaseglob

for img in "$src"/*.(jpg|jpeg|png|tif|tiff|heic|gif|bmp); do
    name="${img:t:r}"
    ext="${img:e}"

    w=$(sips -g pixelWidth "$img" | awk '/pixelWidth/ {print $2}')
    h=$(sips -g pixelHeight "$img" | awk '/pixelHeight/ {print $2}')
    if [[ -z "$w" || -z "$h" ]]; then
        echo "Skipping $img: could not read dimensions" >&2
        continue
    fi

    left_w=$(( w / 2 ))
    right_w=$(( w - left_w ))

    #echo "$w x $h -> $left_w, $right_w"

    imageprep -a c "$left_w" "$h"  --cropfrom tl -s "$img" -d "$out/${name}-L.${ext}" >/dev/null
    imageprep -a c "$right_w" "$h" --cropfrom tr -s "$img" -d "$out/${name}-R.${ext}" >/dev/null

    #sips -c "$h" "$left_w" --cropOffset 0 0.1        "$img" --out "$out/${name}-L.${ext}" >/dev/null
    #sips -c "$h" "$right_w" --cropOffset 0 "$left_w" "$img" --out "$out/${name}-R.${ext}" >/dev/null

    echo "Split ${img:t} (${w}x${h}) -> ${name}-L.${ext}, ${name}-R.${ext}"
done
