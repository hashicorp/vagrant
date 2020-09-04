#!/bin/bash
set -xe

apt-get update -q
apt-get install -qy linux-headers-$(uname -r)
apt-get install -qy virtualbox
apt-get install -qy nfs-kernel-server

pushd /vagrant

dpkg -i vagrant_*_x86_64.deb
vagrant plugin install ./vagrant-spec.gem

popd
