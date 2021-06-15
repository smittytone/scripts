#!/bin/zsh

# binstall.zsh
#
# install key scripts into $HOME/bin
# NOTE Depends upon $GIT/dotfiles/Mac/keyscripts
#      ie. $GIT must be set, and
#      to list the files to be copied and made executable
#
# @version   1.3,o

app_version="1.3.0"
bin_dir=$HOME/bin
source_file=$GIT/dotfiles/Mac/keyscripts
scripts_dir=$GIT/scripts
do_show=1
repos=()
states=()
versions=()
max=0

# FROM 1.1.0
# Display the version if requested
get_version() {
    if [[ $do_show -eq 1 ]]; then
        script=$(cat "$1")
        result=$(grep '# @version' < <(echo -e "$script"))
        result=$(tr -s " " < <(echo -e "$result"))
        version=$(echo "$result" | cut -d " " -s -f 3)
        repos+=(${1:t})
        versions+=($version)
        if [[ "$2" == "N" ]]; then
            states+=("Unchanged")
            #echo "  ${1:t} unchanged at version $version"
        else
            states+=("Updated")
            #echo "* ${1:t} updated to version $version"
        fi

        if [[ ${#1:t} -gt $max ]] max=${#1:t}
    fi
}

# FROM 1.3.0
# Print the output table header
print_header() {
    printf '%-*s | %-9s | %s\n' $max "Utility" "State" "Version"
    printf '-%.0s' {0..$max}
    printf '+-----------+--------\n'
}

# FROM 1.1.0
# Check args to silence version display
for arg in "$@"; do
    arg=${arg:l}
    if [[ "$arg" == "-q" || "$arg" == "--quiet" ]]; then
        do_show=0
    fi

    if [[ "$arg" == "--version" ]]; then
        echo "binstall $app_version"
        exit 0
    fi
done

# Check for a ~/bin directory and make if it's not there yet
if [[ ! -e $bin_dir ]]; then
    mkdir -p $bin_dir || echo 'Could not create ~/bin -- exiting' ; exit 1
fi

# Load in the list of scripts
if [[ -e $source_file ]]; then
    if [[ -e $scripts_dir ]]; then
        # Read in each line of 'keyscripts', each of which
        # is the name of a script to copy, eg. 'update.zsh'
        while IFS= read -r line; do
            target_file=$HOME/bin/${line:t:r}

            # FROM 1.0.1 -- check of the source and target are different
            # FROM 1.0.2 -- don't block install of uninstalled scripts
            diff_result="DO"
            if [[ -e $target_file ]]; then
                diff_result=$(diff $target_file $scripts_dir/$line)
            fi

            # FROM 1.0.1
            # Only copy if the file is different
            if [[ -n $diff_result ]]; then
                cp $scripts_dir/$line $target_file
                get_version $target_file Y
            else
                get_version $target_file N
            fi

            # Make the file executable
            chmod +x $target_file
        done < $source_file
    else
        echo "'$scripts_dir' does not exist... exiting"
    fi
else
    echo "'$source_file' does not exist... exiting"
fi

# Display the output
# FROM 1.3.0 -- as a table
print_header
for (( i = 1 ; i <= ${#repos[@]} ; i++ )); do
    printf '%-*s | %-9s | %s\n' $max ${repos[i]} ${states[i]} ${versions[i]}
done