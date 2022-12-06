#!/usr/bin/env bash

# NOTE: This release will generate a new release on the installers
# repository which in turn triggers a full package build
target_owner="hashicorp"
target_repository="vagrant-builders"

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/init.sh"

pushd "${root}"

# Install ghr
install_ghr

# Build our gem
wrap gem build ./*.gemspec \
     "Failed to build Vagrant RubyGem"

# Get the path of our new gem
g=(vagrant*.gem)
gem=$(printf "%s" "${g[0]}")

# Determine the version of the release
vagrant_version="$(gem specification "${gem}" version)"
vagrant_version="${vagrant_version##*version: }"

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
wrap zip "vagrant-go_${vagrant_version}_linux_amd64.zip" vagrant-go_linux_amd64 \
     "Failed to compress go linux amd64 binary"

# Build linux 386 binary
wrap make bin/linux-386 \
     "Failed to build the Vagrant go linux 386 binary"

# Rename our binary
wrap mv vagrant vagrant-go_linux_386 \
     "Failed to rename vagrant linux 386 binary"

# Zip the binary
wrap zip "vagrant-go_${vagrant_version}_linux_386.zip" vagrant-go_linux_386 \
     "Failed to compress go linux 386 binary"

# Build darwin binary
wrap make bin/darwin \
     "Failed to build the Vagrant go darwin amd64 binary"

# Rename our binary
wrap mv vagrant vagrant-go_darwin_amd64 \
     "Failed to rename vagrant darwin amd64 binary"

# Zip the binary
wrap zip "vagrant-go_${vagrant_version}_darwin_amd64.zip" vagrant-go_darwin_amd64 \
     "Failed to compress go darwin amd64 binary"

wrap mkdir release-assets \
    "Failed to create release assets directory"

wrap mv vagrant*.gem release-assets \
    "Failed to move Vagrant RubyGem asset to release asset directory"
wrap mv vagrant-go*.zip release-assets \
    "Failed to move Vagrant go assets to release asset directory"

# We want to release into the builders repository so
# update the repository variable with the desired destination
repo_owner="${target_owner}"
repo_name="${target_repository}"
full_sha="main"

# Use the hashibot token since we are creating the (pre)release
# in a different repository.
export GITHUB_TOKEN="${HASHIBOT_TOKEN}"

if [ -z "${tag}" ]; then
    echo "Generating Vagrant RubyGem pre-release... "
    version="v${vagrant_version}+${short_sha}"
    prerelease "${version}" ./release-assets
else
    # Validate this is a proper release version
    if ! valid_release_version "${vagrant_version}"; then
        fail "Invalid version format for Vagrant release: ${vagrant_version}"
    fi

    echo "Generating Vagrant RubyGem release... "
    version="v${vagrant_version}"
    release "${version}" ./release-assets
fi

slack -m "New Vagrant installers release triggered: *${version}*"
