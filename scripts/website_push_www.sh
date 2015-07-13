#!/bin/bash

# Get the parent directory of where this script is.
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )/.." && pwd )"

# Change into that directory
cd $DIR

# Add the git remote if it doesn't exist
git remote | grep heroku-www || {
    git remote add heroku-www git@heroku.com:vagrantup-www-2.git
}

# Push the subtree (force)
git push heroku-www `git subtree split --prefix website/www master`:master --force
