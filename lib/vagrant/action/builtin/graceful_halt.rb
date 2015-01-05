require "log4r"
require "timeout"

module Vagrant
  module Action
    module Builtin
      # This middleware class will attempt to perform a graceful shutdown
      # of the machine using the guest implementation. This middleware is
      # compatible with the {Call} middleware so you can branch based on
      # the result, which is true if the halt succeeded and false otherwise.
      class GracefulHalt
        # Note: Any of the arguments can be arrays as well.
        #
        # @param [Symbol] target_state The target state ID that means that
        #   the machine was properly shut down.
        # @param [Symbol] source_state The source state ID that the machine
        #   must be in to be shut down.
        def initialize(app, env, target_state, source_state=nil)
          @app          = app
          @logger       = Log4r::Logger.new("vagrant::action::builtin::graceful_halt")
          @source_state = source_state
          @target_state = target_state
        end

        def call(env)
          graceful = true
          graceful = !env[:force_halt] if env.key?(:force_halt)

          # By default, we didn't succeed.
          env[:result] = false

          if graceful && @source_state
            @logger.info("Verifying source state of machine: #{@source_state.inspect}")

            # If we're not in the proper source state, then we don't
            # attempt to halt the machine
            current_state = env[:machine].state.id
            if current_state != @source_state
              @logger.info("Invalid source state, not halting: #{current_state}")
              graceful = false
            end
          end

          # Only attempt to perform graceful shutdown under certain cases
          # checked above.
          if graceful
            env[:ui].output(I18n.t("vagrant.actions.vm.halt.graceful"))

            begin
              env[:machine].guest.capability(:halt)

              @logger.debug("Waiting for target graceful halt state: #{@target_state}")
              begin
                Timeout.timeout(env[:machine].config.vm.graceful_halt_timeout) do
                  while env[:machine].state.id != @target_state
                    sleep 1
                  end
                end
              rescue Timeout::Error
                # Don't worry about it, we catch the case later.
              end
            rescue Errors::GuestCapabilityNotFound
              # This happens if insert_public_key is called on a guest that
              # doesn't support it. This will block a destroy so we let it go.
            rescue Errors::MachineGuestNotReady
              env[:ui].detail(I18n.t("vagrant.actions.vm.halt.guest_not_ready"))
            end

            # The result of this matters on whether we reached our
            # proper target state or not.
            env[:result] = env[:machine].state.id == @target_state

            if env[:result]
              @logger.info("Gracefully halted.")
            else
              @logger.info("Graceful halt failed.")
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
