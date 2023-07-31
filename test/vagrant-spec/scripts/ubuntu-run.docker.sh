#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


export VAGRANT_SPEC_DOCKER_IMAGE="${VAGRANT_SPEC_DOCKER_IMAGE}"

# Explicitly use Go binary
export VAGRANT_PATH=/vagrant/vagrant

# Explicitly set high open file limits... vagrant-ruby tends to run into the
# default 1024 limit during some operations.
ulimit -n 65535

vagrant-spec ${VAGRANT_SPEC_ARGS} --config /vagrant/test/vagrant-spec/configs/vagrant-spec.config.docker.rb
result=$?

exit $result
