#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

pushd "${root}" > /dev/null

export DEBIAN_FRONTEND="noninteractive"

# Install required dependencies
sudo apt-get update || exit 1
sudo apt-get install -yq bsdtar || exit 1

# Ensure bundler is installed
gem install --no-document bundler || exit 1

# Install the bundle
bundle install || exit 1

# Run tests
bundle exec rake test:unit

result=$?
popd > /dev/null

exit $result
