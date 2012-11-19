module Vagrant
  module Plugin
    module V2
      # This is the container class for the components of a single plugin.
      class Components
        attr_reader :provider_configs

        def initialize
          @provider_configs = Registry.new
        end
      end
    end
  end
end
