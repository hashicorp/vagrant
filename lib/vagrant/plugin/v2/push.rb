module Vagrant
  module Plugin
    module V2
      class Push
        attr_reader :env
        attr_reader :config

        # Initializes the pusher with the given environment the push
        # configuration.
        #
        # @param [Environment] env
        # @param [Object] config Push configuration
        def initialize(env, config)
          @env     = env
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
