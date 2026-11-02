#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

set -e

apt-get update -q
apt-get install -qq -y --force-yes curl apt-transport-https
apt-get purge -qq -y lxc-docker* || true
curl -sSL https://get.docker.com/ | sh

/bin/bash /vagrant/test/vagrant-spec/scripts/ubuntu-install-vagrant.sh

