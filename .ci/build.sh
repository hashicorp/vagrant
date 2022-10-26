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
gem=$(printf "%s" "${g[0]}")

# Store the gem asset
wrap aws s3 cp "${gem}" "${ASSETS_PRIVATE_BUCKET}/${repository}/vagrant-main.gem" \
     "Failed to store Vagrant RubyGem main build"

# Install submodules
wrap git submodule update --init --recursive \
     "Failed to install git submodules"

# Build our binaries

# Build linux amd64 binary
wrap make bin/linux \
     "Failed to build the Vagrant go linux amd64 binary"

# Rename our binary
wrap mv vagrant vagrant-go_linux_amd64 \
     "Failed to rename vagrant linux amd64 binary"

# Zip the binary
wrap zip vagrant-go_linux_amd64 vagrant-go_linux_amd64 \
     "Failed to compress go linux amd64 binary"

# Store the binary asset
wrap aws s3 cp vagrant-go_linux_amd64.zip "${ASSETS_PRIVATE_BUCKET}/${repository}/vagrant-go_main_linux_amd64.zip" \
     "Failed to store Vagrant Go linux amd64 main build"

# Build linux 386 binary
wrap make bin/linux-386 \
     "Failed to build the Vagrant go linux 386 binary"

# Rename our binary
wrap mv vagrant vagrant-go_linux_386 \
     "Failed to rename vagrant linux 386 binary"

# Zip the binary
wrap zip vagrant-go_linux_386 vagrant-go_linux_386 \
     "Failed to compress go linux 386 binary"

# Store the binary asset
wrap aws s3 cp vagrant-go_linux_386.zip "${ASSETS_PRIVATE_BUCKET}/${repository}/vagrant-go_main_linux_386.zip" \
     "Failed to store Vagrant Go linux 386 main build"

# Build darwin binary
wrap make bin/darwin \
     "Failed to build the Vagrant go darwin amd64 binary"

# Rename our binary
wrap mv vagrant vagrant-go_darwin_amd64 \
     "Failed to rename vagrant darwin amd64 binary"

# Zip the binary
wrap zip vagrant-go_darwin_amd64 vagrant-go_darwin_amd64 \
     "Failed to compress go darwin amd64 binary"

# Store the binary asset
wrap aws s3 cp vagrant-go_darwin_amd64.zip "${ASSETS_PRIVATE_BUCKET}/${repository}/vagrant-go_main_darwin_amd64.zip" \
     "Failed to store Vagrant Go darwin amd64 main build"
