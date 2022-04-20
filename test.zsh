#!/bin/zsh

got_utitool=$(which utitool)

if [[ -z $got_utitool ]]; then
    echo "[ERROR] utitool not installed"
    exit 1
fi

files=()
utis=()
max_file=10

for file in ./*(.); do
    file_ext=${file:t:r}
    if [[ "$file_ext" == "test" ]]; then
        uti=$(utitool $file)
        uti=$(echo "$uti" | cut -d ":" -f 2)
        utis+=($uti)
        files+=($file)
        if [[ ${#file} -gt ${max_file} ]] max_file=${#file}
    fi
done

format_string="%-*s %s\n"
for (( i = 1 ; i <= ${#utis[@]} ; i++ )); do
    printf ${format_string} ${max_file} ${files[i]} ${utis[i]}
done