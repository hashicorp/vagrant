#!/bin/bash
set -xe

apt-get update
apt-get install -qq -y --force-yes curl apt-transport-https
apt-get purge -qq -y lxc-docker* || true
curl -sSL https://get.docker.com/ | sh

pushd /vagrant

dpkg -i vagrant_*_x86_64.deb
vagrant plugin install ./vagrant-spec.gem

popd
