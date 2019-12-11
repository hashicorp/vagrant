require File.expand_path("../version_6_0", __FILE__)

module VagrantPlugins
  module ProviderVirtualBox
    module Driver
      # Driver for VirtualBox 6.1.x
      class Version_6_1 < Version_6_0
        def initialize(uuid)
          super

          @logger = Log4r::Logger.new("vagrant::provider::virtualbox_6_1")
        end
      end
    end
  end
end
