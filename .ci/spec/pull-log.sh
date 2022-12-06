#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../../" && pwd )"

. "${root}/.ci/load-ci.sh"
. "${root}/.ci/spec/env.sh"

pushd "${root}" > "${output}"

# Use same setup as run-tests.sh so `vagrant ssh` will work.

unset PACKET_EXEC_PRE_BUILTINS

# spec test configuration, defined by action runners, used by Vagrant on packet
export PKT_VAGRANT_HOST_BOXES="${VAGRANT_HOST_BOXES}"
export PKT_VAGRANT_GUEST_BOXES="${VAGRANT_GUEST_BOXES}"
# other vagrant-spec options
export PKT_VAGRANT_HOST_MEMORY="${VAGRANT_HOST_MEMORY:-10000}"
export PKT_VAGRANT_CWD="test/vagrant-spec/"
export PKT_VAGRANT_VAGRANTFILE=Vagrantfile.spec
export PKT_VAGRANT_SPEC_PROVIDERS="${VAGRANT_SPEC_PROVIDERS}"
export PKT_VAGRANT_DOCKER_IMAGES="${VAGRANT_DOCKER_IMAGES}"

echo "Pulling log..."
packet-exec run -download vagrant-spec.log "vagrant ssh -c \"cat /tmp/vagrant-spec.log\" > vagrant-spec.log"
