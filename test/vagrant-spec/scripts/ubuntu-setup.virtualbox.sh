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
sudo snap install ruby --classic --channel=2.7/stable

pushd /vagrant

# Get vagrant-plugin-sdk repo
git config --global url."https://${HASHIBOT_USERNAME}:${HASHIBOT_TOKEN}@github.com".insteadOf "https://github.com"

# Build Vagrant artifacts
gem install bundler -v "$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1)"
make
bundle install
./vagrant status

# dpkg -i vagrant_*_x86_64.deb
# vagrant plugin install ./vagrant-spec.gem

popd
