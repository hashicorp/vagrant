#!/bin/bash

# Get the parent directory of where this script is.
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )/.." && pwd )"

# Change into that directory
cd $DIR

# Add the git remote if it doesn't exist
git remote | grep heroku-docs || {
    git remote add heroku-docs git@heroku.com:vagrantup-docs-2.git
}

# Push the subtree (force)
git push heroku-docs `git subtree split --prefix website/docs master`:master --force
