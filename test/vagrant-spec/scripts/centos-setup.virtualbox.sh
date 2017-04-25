#!/bin/bash
set -xe

curl -Lo /etc/yum.repos.d/virtualbox.repo http://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo
yum groupinstall -y "Development Tools"
yum install -y kernel-devel
yum install -y VirtualBox-${VAGRANT_CENTOS_VIRTUALBOX_VERSION:-5.1}

pushd /vagrant

rpm -ivh ./pkg/dist/vagrant_*_x86_64.rpm
vagrant plugin install ./vagrant-spec.gem

popd
