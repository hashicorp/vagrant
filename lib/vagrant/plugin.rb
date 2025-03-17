# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module Vagrant
  module Plugin
    autoload :V1,        "vagrant/plugin/v1"
    autoload :V2,        "vagrant/plugin/v2"
    autoload :Manager,   "vagrant/plugin/manager"
    autoload :StateFile, "vagrant/plugin/state_file"
  end
end
