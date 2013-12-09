#!/bin/bash
set -e

# Get the parent directory of where this script is.
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )/.." && pwd )"

# Change into that dir because we expect that
cd $DIR

# Get the version from the command line
VERSION=$1
if [ -z $VERSION ]; then
    echo "Please specify a version."
    exit 1
fi

# Make sure we have a bintray API key
if [ -z $BINTRAY_API_KEY ]; then
    echo "Please set your bintray API key in the BINTRAY_API_KEY env var."
    exit 1
fi

# Calculate the checksums
pushd ./dist
shasum -a256 * > ./${VERSION}_SHA256SUMS
popd

# Upload
for ARCHIVE in ./dist/*; do
    ARCHIVE_NAME=$(basename ${ARCHIVE})

    echo Uploading: $ARCHIVE_NAME
    curl \
        -T ${ARCHIVE} \
        -umitchellh:${BINTRAY_API_KEY} \
        "https://api.bintray.com/content/mitchellh/vagrant/vagrant/${VERSION}/${ARCHIVE_NAME}"
done
