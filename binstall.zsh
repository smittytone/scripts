#!/bin/zsh

# binstall.zsh
#
# install key scripts into $HOME/bin
# NOTE Depends upon $GIT/dotfiles/Mac/keyscripts
#      ie. $GIT must be set, and
#      to list the files to be copied and made executable
#
# @version 1.0.1

bin_dir=$HOME/bin
source_file=$GIT/dotfiles/Mac/keyscripts
scripts_dir=$GIT/scripts

if [[ ! -e $bin_dir ]]; then
    mkdir -p $bin_dir || echo 'Could not create ~/bin -- exiting' ; exit 1
fi

if [[ -e $source_file ]]; then
    if [[ -e $scripts_dir ]]; then
        # Read in each line of 'keyscripts', each of which
        # is the name of a script to copy, eg. 'update.zsh'
        while IFS= read -r line; do
            target_file=$HOME/bin/${line:t:r}

            # FROM 1.0.1
            # Check of the source and target are different
            diff_result=""
            if [[ -e $target_file ]]; then
                diff_result=$(diff $target_file $scripts_dir/$line)
            fi

            # FROM 1.0.1
            # Only copy if the file is different
            if [[ -n $diff_result ]]; then
                cp $scripts_dir/$line $target_file
                #echo "DEBUG $scripts_dir/$line copied"
            else
                #echo "DEBUG $scripts_dir/$line unchanged"
            fi

            # Make the file executable
            chmod +x $target_file
        done < $source_file
    else
        echo "'$scripts_dir' does not exits... exiting"
    fi
else
    echo "'$source_file' does not exits... exiting"
fi