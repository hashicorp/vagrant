require File.expand_path("../version_5_0", __FILE__)

module VagrantPlugins
  module ProviderVirtualBox
    module Driver
      # Driver for VirtualBox 6.0.x
      class Version_6_0 < Version_5_0
        def initialize(uuid)
          super

          @logger = Log4r::Logger.new("vagrant::provider::virtualbox_6_0")
        end
      end
    end
  end
end
