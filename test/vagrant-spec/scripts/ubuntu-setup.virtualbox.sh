#!/bin/bash
set -xe

apt-get update -q
apt-get install -qy linux-headers-$(uname -r)
apt-get install -qy virtualbox
apt-get install -qy nfs-kernel-server

/bin/bash /vagrant/test/vagrant-spec/scripts/ubuntu-install-vagrant.sh


