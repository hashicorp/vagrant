#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/load-ci.sh"

pushd "${root}"

info "Building Vagrant RubyGem..."
wrap gem build ./*.gemspec \
     "Failed to build Vagrant RubyGem"

# Get the path of our new gem
files=( vagrant*.gem )
gem="${files[0]}"
if [ ! -f "${gem}" ]; then
     debug "could not locate gem in %s" "${files[*]}"
     failure "Unable to locate built Vagrant RubyGem"
fi

# Create folder to store artifacts
wrap mkdir -p "generated-artifacts" \
     "Failed to create artifiact directory"

wrap mv "${gem}" ./generated-artifacts \
     "Failed to move Vagrant RubyGem"

info "Installing submodules for vagrant-go build..."
wrap git submodule update --init --recursive \
     "Failed to install git submodules"

# Build our binaries

info "Building vagrant-go linux amd64..."

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

info "Building vagrant-go linux 386..."

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

info "Building vagrant-go darwin amd64..."

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

info "Storing commit ID information..."
printf "%s\n" "${full_sha}" > ./generated-artifacts/commit-id.txt

if github_draft_release_exists "vagrant" "${ident_ref}"; then
     debug "found existing draft release for %s, deleting existing drafts" "${ident_ref}"
     github_delete_draft_release "${ident_ref}"
fi

info "Storing artifacts in draft release '%s'..." "${ident_ref}"

# Store the artifacts for the builders
draft_release "${ident_ref}" ./generated-artifacts
