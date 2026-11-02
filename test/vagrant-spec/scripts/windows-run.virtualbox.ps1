# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

cd /vagrant
vagrant plugin install ./vagrant-spec.gem

if ( $env:VAGRANT_EXPERIMENTAL -eq "" ) {
  $env:VAGRANT_EXPERIMENTAL="1"
}
vagrant vagrant-spec $Env:VAGRANT_SPEC_ARGS /vagrant/test/vagrant-spec/configs/vagrant-spec.config.virtualbox.rb
