module Vagrant
  module Plugin
    module V2
      class Push
        attr_reader :machine
        attr_reader :config

        # Initializes the pusher with the machine that exists for this project
        # as well as the configuration (the push configuration, not the full machine
        # configuration).
        #
        # The pusher should _not_ do anything at this point except
        # initialize internal state.
        #
        # @param [Machine] machine The machine associated with this code.
        # @param [Object] config Push configuration, if one was set.
        def initialize(machine, config)
          @machine = machine
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
