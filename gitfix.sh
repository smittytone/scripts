#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash

echo "GitFix"
read -n 1 p "You should be in your project directory. Press [G] to continue, or [C] to cancel " key
key=${key^^*}

if [ $key = "G" ]; then
    git rm -r --cached .
    git add .
    git commit -m ".gitignore is now working"
fi