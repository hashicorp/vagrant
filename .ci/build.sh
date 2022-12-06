#!/usr/bin/env bash

success="✅"

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/init.sh"

pushd "${root}"

echo -n "Building RubyGem... "

# Build our gem
wrap gem build ./*.gemspec \
     "Failed to build Vagrant RubyGem"

echo "${success}"

# Get the path of our new gem
g=(vagrant*.gem)
gem=$(printf "%s" "${g[0]}")

# Create folder to store artifacts
wrap mkdir -p "generated-artifacts" \
     "Failed to create artifiact directory"

wrap mv "${gem}" ./generated-artifacts \
     "Failed to move Vagrant RubyGem"

# Install submodules
wrap git submodule update --init --recursive \
     "Failed to install git submodules"

# Build our binaries

echo -n "Building vagrant-go linux amd64... "

# Build linux amd64 binary
wrap make bin/linux \
     "Failed to build the Vagrant go linux amd64 binary"

# Rename our binary
wrap mv vagrant vagrant-go_linux_amd64 \
     "Failed to rename vagrant linux amd64 binary"

# Zip the binary
wrap zip vagrant-go_linux_amd64 vagrant-go_linux_amd64 \
     "Failed to compress go linux amd64 binary"

# Move the binary asset
wrap mv vagrant-go_linux_amd64.zip ./generated-artifacts \
     "Failed to move Vagrant Go linux amd64 build"

echo "${success}"
echo -n "Building vagrant-go linux 386... "

# Build linux 386 binary
wrap make bin/linux-386 \
     "Failed to build the Vagrant go linux 386 binary"

# Rename our binary
wrap mv vagrant vagrant-go_linux_386 \
     "Failed to rename vagrant linux 386 binary"

# Zip the binary
wrap zip vagrant-go_linux_386 vagrant-go_linux_386 \
     "Failed to compress go linux 386 binary"

# Move the binary asset
wrap mv vagrant-go_linux_386.zip ./generated-artifacts \
     "Failed to move Vagrant Go linux 386 build"

echo "${success}"
echo -n "Building vagrant-go darwin amd64... "

# Build darwin binary
wrap make bin/darwin \
     "Failed to build the Vagrant go darwin amd64 binary"

# Rename our binary
wrap mv vagrant vagrant-go_darwin_amd64 \
     "Failed to rename vagrant darwin amd64 binary"

# Zip the binary
wrap zip vagrant-go_darwin_amd64 vagrant-go_darwin_amd64 \
     "Failed to compress go darwin amd64 binary"

# Move the binary asset
wrap mv vagrant-go_darwin_amd64.zip ./generated-artifacts \
     "Failed to move Vagrant Go darwin amd64 build"

echo "${success}"
echo -n "Storing artifacts... "

# Store the artifacts for the builders
draft_release "${ident_ref}" ./generated-artifacts

echo "${success}"
