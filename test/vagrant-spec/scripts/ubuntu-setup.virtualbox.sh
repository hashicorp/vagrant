#!/bin/bash
set -xe

apt-get update -q
apt-get install -qy linux-headers-$(uname -r)
apt-get install -qy virtualbox
apt-get install -qy nfs-kernel-server

# Install Go
wget -O go.tar.gz https://go.dev/dl/go1.17.6.linux-amd64.tar.gz
tar -xzf go.tar.gz --directory /usr/local
export PATH=$PATH:/usr/local/go/bin
go version

# Install Ruby
curl -sSL https://rvm.io/pkuczynski.asc | sudo gpg --import -
curl -sSL https://get.rvm.io | bash -s stable --ruby

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
