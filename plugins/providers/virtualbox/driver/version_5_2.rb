require File.expand_path("../version_5_0", __FILE__)

module VagrantPlugins
  module ProviderVirtualBox
    module Driver
      # Driver for VirtualBox 5.2.x
      class Version_5_2 < Version_5_0
        def initialize(uuid)
          super

          @logger = Log4r::Logger.new("vagrant::provider::virtualbox_5_2")
        end
      end
    end
  end
end
