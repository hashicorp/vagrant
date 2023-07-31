# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  module Plugin
    autoload :V1,        "vagrant/plugin/v1"
    autoload :V2,        "vagrant/plugin/v2"
    autoload :Remote,    "vagrant/plugin/remote"
    autoload :Manager,   "vagrant/plugin/manager"
    autoload :StateFile, "vagrant/plugin/state_file"
  end
end
