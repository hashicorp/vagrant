#!/bin/bash
set -x

export VAGRANT_SPEC_BOX="${VAGRANT_SPEC_BOX}"
vagrant vagrant-spec /vagrant/test/vagrant-spec/configs/vagrant-spec.config.virtualbox.rb
result=$?

exit $result
