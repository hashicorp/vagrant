# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require File.expand_path("../version_7_0", __FILE__)

module VagrantPlugins
  module ProviderVirtualBox
    module Driver
      # Driver for VirtualBox 7.1.x
      class Version_7_1 < Version_7_0
        def initialize(uuid)
          super

          @logger = Log4r::Logger.new("vagrant::provider::virtualbox_7_1")
        end
      end
    end
  end
end
