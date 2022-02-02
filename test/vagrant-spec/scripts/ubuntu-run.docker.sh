#!/bin/bash
set -x

export VAGRANT_SPEC_DOCKER_IMAGE="${VAGRANT_SPEC_DOCKER_IMAGE}"
vagrant-spec ${VAGRANT_SPEC_ARGS} --config /vagrant/test/vagrant-spec/configs/vagrant-spec.config.docker.rb
result=$?

exit $result
