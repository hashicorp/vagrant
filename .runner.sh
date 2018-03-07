#!/usr/bin/env bash

set -e

mkdir -p assets
gem build *.gemspec
mv vagrant-*.gem assets/
