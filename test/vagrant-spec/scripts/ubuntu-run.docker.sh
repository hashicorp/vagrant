#!/bin/bash
set -x

export VAGRANT_SPEC_DOCKER_IMAGE="${VAGRANT_SPEC_DOCKER_IMAGE}"
vagrant vagrant-spec ${VAGRANT_SPEC_ARGS} /vagrant/test/vagrant-spec/configs/vagrant-spec.config.docker.rb
result=$?

exit $result
