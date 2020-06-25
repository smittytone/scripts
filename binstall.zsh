#!/bin/zsh

# binstall.zsh
#
# install key scripts into $HOME/bin
# NOTE Depends upon $GIT/dotfiles/Mac/keyscripts
#      ie. $GIT must be set, and
#      to list the files to be copied and made executable
#
# @version 1.0.0

source_file=$GIT/dotfiles/Mac/keyscripts
scripts_dir=$GIT/scripts
if [[ -e $source_file ]]; then
    if [[ -e $scripts_dir ]]; then
        # Read in each line of 'keyscripts', each of which
        # is the name of a script to copy, eg. 'update.zsh'
        while IFS= read -r line; do
            target_file=$HOME/bin/${line:t:r}
            cp $scripts_dir/$line $target_file
            # Make the file executable
            chmod +x $target_file
        done < $source_file
    else
        echo "'$scripts_dir' does not exits... exiting"
    fi
else
    echo "'$source_file' does not exits... exiting"
fi