#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../../" && pwd )"

. "${root}/.ci/common.sh"
. "${root}/.ci/spec/env.sh"

pushd "${root}" > "${output}"

# Assumes packet is already set up

# spec test configuration, defined by action runners, used by Vagrant on packet
export PKT_VAGRANT_HOST_BOXES="${VAGRANT_HOST_BOXES}"
export PKT_VAGRANT_GUEST_BOXES="${VAGRANT_GUEST_BOXES}"
# other vagrant-spec options
export PKT_VAGRANT_HOST_MEMORY="${VAGRANT_HOST_MEMORY:-10000}"
export PKT_VAGRANT_CWD="test/vagrant-spec/"
export PKT_VAGRANT_VAGRANTFILE=Vagrantfile.spec
###

# Grab vagrant-spec gem and place inside root dir of Vagrant repo
# TODO put back the wrap and error message below
aws s3 cp "${ASSETS_PRIVATE_BUCKET}/vagrant-spec/vagrant-spec.gem" "vagrant-spec.gem"
###

# Run the job

echo "Creating vagrant spec guests..."
wrap_stream packet-exec run -upload --  "vagrant up --no-provision --provider vmware_desktop" \
                                        "Vagrant Blackbox host creation command failed"


echo "Finished bringing up vagrant spec guests"
