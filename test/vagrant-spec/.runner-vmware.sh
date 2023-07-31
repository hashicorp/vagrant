#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


function cleanup {
    vagrant destroy --force
}

trap cleanup EXIT

GEM_PATH=$(ls vagrant-spec*.gem)

set -ex

if [ -f "${GEM_PATH}" ]
then
    mv "${GEM_PATH}" vagrant-spec.gem
fi

vagrant box update
vagrant box prune

guests=$(vagrant status | grep vmware | awk '{print $1}')

vagrant up --no-provision

declare -A pids

for guest in ${guests}
do
    vagrant provision ${guest} &
    pids[$guest]=$!
    sleep 60
done

result=0
set +e

for guest in ${guests}
do
    wait ${pids[$guest]}
    if [ $? -ne 0 ]
    then
        echo "Provision failure for: ${guest}"
        result=1
    fi
done

exit $result
