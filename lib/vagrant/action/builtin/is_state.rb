module Vagrant
  module Action
    module Builtin
      # This middleware is meant to be used with Call and can check if
      # a machine is in the given state ID.
      class IsState
        # Note: Any of the arguments can be arrays as well.
        #
        # @param [Symbol] target_state The target state ID that means that
        #   the machine was properly shut down.
        # @param [Symbol] source_state The source state ID that the machine
        #   must be in to be shut down.
        def initialize(app, env, check, **opts)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::is_state")
          @check  = check
          @invert = !!opts[:invert]
        end

        def call(env)
          @logger.debug("Checking if machine state is '#{@check}'")
          state = env[:machine].state.id
          @logger.debug("-- Machine state: #{state}")

          env[:result] = @check == state
          env[:result] = !env[:result] if @invert
          @app.call(env)
        end
      end
    end
  end
end
