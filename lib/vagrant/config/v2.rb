# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  module Config
    module V2
      autoload :DummyConfig, "vagrant/config/v2/dummy_config"
      autoload :Loader, "vagrant/config/v2/loader"
      autoload :Root, "vagrant/config/v2/root"
      autoload :Util, "vagrant/config/v2/util"
    end
  end
end
