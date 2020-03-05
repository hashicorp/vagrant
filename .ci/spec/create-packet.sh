#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/spec/env.sh"
. "${root}/.ci/common.sh"

pushd "${root}" > "${output}"

# Define a custom cleanup function to destroy any orphan guests
# on the packet device
function cleanup() {
    (>&2 echo "Cleaning up packet device")
    unset PACKET_EXEC_PERSIST
    pkt_wrap_stream "cd vagrant;VAGRANT_CWD=test/vagrant-spec/ VAGRANT_VAGRANTFILE=Vagrantfile.spec vagrant destroy -f" \
                "Vagrant command failed"
}

# Ensure we have a packet device to connect
echo "Creating packet device if needed..."

packet-exec info

if [ $? -ne 0 ]; then
    wrap_stream packet-exec create \
                "Failed to create packet device"
fi

echo "Finished creating spec test packet instance"
