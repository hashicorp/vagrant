#!/bin/bash
set -x

export VAGRANT_EXPERIMENTAL="${VAGRANT_EXPERIMENTAL:-1}"
export VAGRANT_SPEC_BOX="${VAGRANT_SPEC_BOX}"

# Explicitly use Go binary
export VAGRANT_PATH=/vagrant/vagrant

vagrant-spec ${VAGRANT_SPEC_ARGS} --config /vagrant/test/vagrant-spec/configs/vagrant-spec.config.virtualbox.rb
result=$?

exit $result
