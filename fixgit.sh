#!/usr/bin/env bash

#
# fixgit.sh
#
# Fix Git repos when .gitignore is updated but doesn't take
#
# @author    Tony Smith
# @copyright 2019-20, Tony Smith
# @version   1.0.1
# @license   MIT
#


echo "FixGit"
read -n 1 -s -p "You should be in your project directory. Press [G] to continue, or any other key to cancel " key
key=${key^^*}

if [ "$key" = "G" ]; then
    git rm -r --cached .
    git add .
    git commit -m "[Git Fixed] .gitignore is now working"
    echo "Git Fixed"
fi
