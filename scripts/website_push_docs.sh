#!/bin/bash

# Set the tmpdir
if [ -z "$TMPDIR" ]; then
  TMPDIR="/tmp"
fi

# Create a temporary build dir and make sure we clean it up. For
# debugging, comment out the trap line.
DEPLOY=`mktemp -d /tmp/vagrant-docs-XXXXXX`
trap "rm -rf $DEPLOY" INT TERM EXIT

# Get the parent directory of where this script is.
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )/.." && pwd )"

# Copy into tmpdir
shopt -s dotglob
cp -R $DIR/website/docs/* $DEPLOY/

# Change into that directory
cd $DEPLOY

# Ignore some stuff
touch .gitignore
echo ".sass-cache" >> .gitignore
echo "build" >> .gitignore
echo "vendor" >> .gitignore

# Add everything
git init .
git add .
git commit -q -m "Deploy by $USER"

git remote add heroku git@heroku.com:vagrantup-docs-2.git
git push -f heroku master

# Cleanup the deploy
rm -rf $DEPLOY
