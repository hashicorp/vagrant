#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

set -e

# Install Go
wget -qO go.tar.gz https://go.dev/dl/go1.17.6.linux-amd64.tar.gz
tar -xzf go.tar.gz --directory /usr/local
export PATH=$PATH:/usr/local/go/bin
go version

# Install Ruby
curl -sSL https://rvm.io/pkuczynski.asc | sudo gpg --import -
curl -sSL https://get.rvm.io | bash -s stable
source /usr/local/rvm/scripts/rvm
rvm install ruby-2.7.2
rvm --default use ruby-2.7.2

# Remove RVM's automatically installed bundler integration, which messes w/
# Vagrant's ruby binary invocation
gem uninstall -i /usr/local/rvm/rubies/ruby-2.7.2/lib/ruby/gems/2.7.0 rubygems-bundler

pushd /vagrant

# Get vagrant-plugin-sdk repo
git config --global url."https://${HASHIBOT_USERNAME}:${HASHIBOT_TOKEN}@github.com".insteadOf "https://github.com"

# Build Vagrant artifacts
gem install bundler -v "$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1)"
make
bundle install
gem build -o /tmp/vagrant.gem vagrant.gemspec
gem install /tmp/vagrant.gem

popd

# Install vagrant-spec
git clone https://github.com/hashicorp/vagrant-spec.git
pushd vagrant-spec

# TEMP: We are using a branch of vagrant-spec while we stabilize the changes
# necessary. Once this branch lands we can remove this line and build from main.
git checkout vagrant-ruby

gem build -o /tmp/vagrant-spec.gem vagrant-spec.gemspec
gem install /tmp/vagrant-spec.gem
popd
