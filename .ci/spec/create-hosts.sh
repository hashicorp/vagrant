#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../../" && pwd )"

. "${root}/.ci/load-ci.sh"
. "${root}/.ci/spec/env.sh"

pushd "${root}" > "${output}"

# spec test configuration, defined by action runners, used by Vagrant on packet
export PKT_VAGRANT_HOST_BOXES="${VAGRANT_HOST_BOXES}"
export PKT_VAGRANT_GUEST_BOXES="${VAGRANT_GUEST_BOXES}"
# other vagrant-spec options
export PKT_VAGRANT_HOST_MEMORY="${VAGRANT_HOST_MEMORY:-10000}"
export PKT_VAGRANT_CWD="test/vagrant-spec/"
export PKT_VAGRANT_VAGRANTFILE=Vagrantfile.spec
export PKT_VAGRANT_SPEC_PROVIDERS="${VAGRANT_SPEC_PROVIDERS}"
###

# Grab vagrant-spec gem and place inside root dir of Vagrant repo
wrap aws s3 cp "${ASSETS_PRIVATE_BUCKET}/hashicorp/vagrant-spec/vagrant-spec.gem" "vagrant-spec.gem" \
  "Could not download vagrant-spec.gem from s3 asset bucket"
###

# Grab vagrant installer and place inside root dir of Vagrant repo
if [ -z "${VAGRANT_PRERELEASE_VERSION}" ]; then
  INSTALLER_URL=`curl -s https://api.github.com/repos/hashicorp/vagrant-installers/releases | jq -r '.[0].assets[] | select(.name | contains("_x86_64.deb")) | .browser_download_url'`
else
  INSTALLER_URL=`curl -s https://api.github.com/repos/hashicorp/vagrant-installers/releases/tags/${VAGRANT_PRERELEASE_VERSION} | jq -r '.assets[] | select(.name | contains("_x86_64.deb")) | .browser_download_url'`
fi

wrap curl -fLO ${INSTALLER_URL} \
  "Could not download vagrant installers"
###

# Run the job

echo "Creating vagrant spec guests..."
wrap_stream packet-exec run -upload --  "vagrant up --no-provision --provider vmware_desktop" \
                                        "Vagrant Acceptance host creation command failed"


echo "Finished bringing up vagrant spec guests"
