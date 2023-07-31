#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

set -xe

curl -Lo /etc/yum.repos.d/virtualbox.repo http://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo
yum groupinstall -y "Development Tools"
yum install -y kernel-devel-$(uname -r)
yum install -y VirtualBox-${VAGRANT_CENTOS_VIRTUALBOX_VERSION:-5.1}

# Install Go
wget -qO go.tar.gz https://go.dev/dl/go1.17.6.linux-amd64.tar.gz
tar -xzf go.tar.gz --directory /usr/local
export PATH=$PATH:/usr/local/go/bin
go version

# Install Ruby
curl -sSL https://rvm.io/pkuczynski.asc | sudo gpg --import -
curl -sSL https://get.rvm.io | bash -s stable --ruby
source .bashrc

pushd /vagrant

# Get vagrant-plugin-sdk repo
git config --global url."https://${HASHIBOT_USERNAME}:${HASHIBOT_TOKEN}@github.com".insteadOf "https://github.com"

# Build Vagrant artifacts
gem install bundler -v "$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1)"
make
bundle install
ln -s /vagrant/vagrant /bin/vagrant

popd

# Install vagrant-spec
git clone https://github.com/hashicorp/vagrant-spec.git
pushd vagrant-spec
gem build vagrant-spec.gemspec
gem install vagrant-spec*.gem
vagrant-spec -h
popd
