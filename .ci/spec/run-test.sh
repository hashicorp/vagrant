#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../../" && pwd )"

. "${root}/.ci/spec/env.sh"
. "${root}/.ci/common.sh"

pushd "${root}" > "${output}"

# Assumes packet is already set up

# Define a custom cleanup function to destroy any orphan guests
# on the packet device
function cleanup() {
    (>&2 echo "Cleaning up packet device")
    unset PACKET_EXEC_PERSIST
    pkt_wrap_stream "vagrant destroy -f" \
                "Vagrant command failed"
}

# job_id is provided by common.sh
export PACKET_EXEC_REMOTE_DIRECTORY="${job_id}"

# spec test configuration, defined by action runners, used by Vagrant on packet
export PKT_VAGRANT_HOST_BOXES="${VAGRANT_HOST_BOXES}"
export PKT_VAGRANT_GUEST_BOXES="${VAGRANT_GUEST_BOXES}"
# other vagrant-spec options
export PKT_VAGRANT_HOST_MEMORY=10000
export PKT_VAGRANT_CWD="test/vagrant-spec/"
export PKT_VAGRANT_VAGRANTFILE=Vagrantfile.spec
###

# Run the job

echo "Running vagrant spec tests..."
# Need to make memory customizable for windows hosts
pkt_wrap_stream "vagrant provision --provider vmware_desktop" \
                "Vagrant Blackbox testing command failed"


echo "Finished vagrant spec tests"
