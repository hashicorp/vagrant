#!/bin/bash
set -xe

apt-get update -q
apt-get install -qy virtualbox

pushd /vagrant

dpkg -i ./pkg/dist/vagrant_*_x86_64.deb
vagrant plugin install ./vagrant-spec.gem

popd
