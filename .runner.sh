#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


set -e

mkdir -p assets
gem build *.gemspec
mv vagrant-*.gem assets/
