#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


export VAGRANT_EXPERIMENTAL="${VAGRANT_EXPERIMENTAL:-1}"
export VAGRANT_SPEC_BOX="${VAGRANT_SPEC_BOX}"

# Explicitly use Go binary
export VAGRANT_PATH=/vagrant/vagrant

# Explicitly set high open file limits... vagrant-ruby tends to run into the
# default 1024 limit during some operations.
ulimit -n 65535

vagrant-spec ${VAGRANT_SPEC_ARGS} --config /vagrant/test/vagrant-spec/configs/vagrant-spec.config.virtualbox.rb
result=$?

exit $result
