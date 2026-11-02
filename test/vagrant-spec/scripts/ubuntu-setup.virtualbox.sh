#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

set -e

export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -qqy linux-headers-$(uname -r)
apt-get install -qqy virtualbox
apt-get install -qqy nfs-kernel-server

/bin/bash /vagrant/test/vagrant-spec/scripts/ubuntu-install-vagrant.sh


