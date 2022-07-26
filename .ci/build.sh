#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/init.sh"

pushd "${root}" > "${output}"

# Build our gem
wrap gem build *.gemspec \
     "Failed to build Vagrant RubyGem"

# Get the path of our new gem
g=(vagrant*.gem)
gem=$(printf "%s" "${g}")

# Store the gem asset
wrap aws s3 cp "${gem}" "${ASSETS_PRIVATE_BUCKET}/${repository}/vagrant-main.gem" \
     "Failed to store Vagrant RubyGem main build"

# Build our binary
wrap make \
     "Failed to build the Vagrant go binary"
wrap zip vagrant-go vagrant-go \
     "Failed to compress go binary"

# Store the binary asset
wrap aws s3 cp vagrant-go.zip "${ASSETS_PRIVATE_BUCKET}/${repository}/vagrant-go-main.zip"
