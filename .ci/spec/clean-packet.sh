#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../../" && pwd )"

. "${root}/.ci/load-ci.sh"
. "${root}/.ci/spec/env.sh"

pushd "${root}" > "${output}"

echo "Cleaning up packet device..."

unset PACKET_EXEC_PERSIST
unset PACKET_EXEC_PRE_BUILTINS
# spec test configuration, defined by action runners, used by Vagrant on packet
export PKT_VAGRANT_HOST_BOXES="${VAGRANT_HOST_BOXES}"
export PKT_VAGRANT_GUEST_BOXES="${VAGRANT_GUEST_BOXES}"
# other vagrant-spec options
export PKT_VAGRANT_HOST_MEMORY="${VAGRANT_HOST_MEMORY:-10000}"
export PKT_VAGRANT_CWD="test/vagrant-spec/"
export PKT_VAGRANT_VAGRANTFILE=Vagrantfile.spec
###

wrap_stream packet-exec run -- "vagrant destroy -f" \
                "Vagrant failed to destroy remaining vagrant-spec guests during clean up"


echo "Finished destroying spec test hosts"
