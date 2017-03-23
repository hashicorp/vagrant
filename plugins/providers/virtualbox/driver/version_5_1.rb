require File.expand_path("../version_5_0", __FILE__)

module VagrantPlugins
  module ProviderVirtualBox
    module Driver
      # Driver for VirtualBox 5.1.x
      class Version_5_1 < Version_5_0
        def initialize(uuid)
          super

          @logger = Log4r::Logger.new("vagrant::provider::virtualbox_5_1")
        end
      end
    end
  end
end
