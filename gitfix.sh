#!/usr/local/bin/bash
# NOTE You may need to change the above line to /bin/bash

echo "GitFix"
read -n 1 p "You should be in your project directory. Press [G] to continue, or any other key to cancel " key
key=${key^^*}

if [ "$key" = "G" ]; then
    git rm -r --cached .
    git add .
    git commit -m "[Git Fixed] .gitignore is now working"
    echo "Git Fixed"
fi
