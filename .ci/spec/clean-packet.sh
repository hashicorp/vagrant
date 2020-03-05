#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/spec/env.sh"
. "${root}/.ci/common.sh"

pushd "${root}" > "${output}"

# Ensure we have a packet device to connect
echo "Cleaning up packet device..."

export PKT_VAGRANT_HOST_BOXES="${VAGRANT_HOST_BOXES}"
export PKT_VAGRANT_GUEST_BOXES="${VAGRANT_GUEST_BOXES}"
export PKT_VAGRANT_CWD=test/vagrant-spec/
export PKT_VAGRANT_VAGRANTFILE=Vagrantfile.spec
pkt_wrap_stream "cd vagrant;vagrant destroy -f" \
                "Vagrant command failed"


echo "Finished destroying spec test hosts"
