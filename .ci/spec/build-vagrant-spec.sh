#!/usr/bin/env bash

git clone git@github.com:hashicorp/vagrant-spec.git
cd vagrant-spec
bundle install
gem build vagrant-spec.gemspec
# Assumes this is being run in the same workspace as the main vagrant repo
mv vagrant-spec-*.gem ../vagrant-spec.gem
