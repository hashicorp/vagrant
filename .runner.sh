#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1


set -e

mkdir -p assets
gem build *.gemspec
mv vagrant-*.gem assets/
