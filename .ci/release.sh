#!/usr/bin/env bash

# NOTE: This release will generate a new release on the installers
# repository which in turn triggers a full package build
target_owner="hashicorp"
target_repository="vagrant-builders"

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/common.sh"

pushd "${root}" > "${output}"

# Build our gem
wrap gem build *.gemspec \
     "Failed to build Vagrant RubyGem"

# Get the path of our new gem
g=(vagrant*.gem)
gem=$(printf "%s" "${g}")

# Determine the version of the release
vagrant_version="$(gem specification "${gem}" version)"
vagrant_version="${vagrant_version##*version: }"

# We want to release into the builders repository so
# update the repository variable with the desired destination
repo_owner="${target_owner}"
repo_name="${target_repository}"
export GITHUB_TOKEN="${HASHIBOT_TOKEN}"

if [ "${tag}" = "" ]; then
    echo "Generating Vagrant RubyGem pre-release... "
    version="v${vagrant_version}+${short_sha}"
    prerelease "${version}" "${gem}"
else
    # Validate this is a proper release version
    valid_release_version "${vagrant_version}"
    if [ $? -ne 0 ]; then
        fail "Invalid version format for Vagrant release: ${vagrant_version}"
    fi

    echo "Generating Vagrant RubyGem release... "
    version="v${vagrant_version}"
    release "${version}" "${gem}"
fi

slack -m "New Vagrant installers release triggered: *${version}*"
