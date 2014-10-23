module Vagrant
  module Plugin
    module V2
      class Push
        attr_reader :environment
        attr_reader :config

        # Initializes the pusher with the given environment the push
        # configuration.
        #
        # @param [environment] environment
        # @param [Object] config Push configuration
        def initialize(environment, config)
          @environment = environment
          @config  = config
        end

        # This is the method called when the actual pushing should be
        # done.
        #
        # No return value is expected.
        def push
        end
      end
    end
  end
end
