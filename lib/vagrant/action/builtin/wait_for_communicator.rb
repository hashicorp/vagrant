module Vagrant
  module Action
    module Builtin
      # This waits for the communicator to be ready for a set amount of
      # time.
      class WaitForCommunicator
        def initialize(app, env, states=nil)
          @app    = app
          @states = states
        end

        def call(env)
          # Wait for ready in a thread so that we can continually check
          # for interrupts.
          ready_thr = Thread.new do
            Thread.current[:result] = env[:machine].communicate.wait_for_ready(
              env[:machine].config.vm.boot_timeout)
          end

          # Start a thread that verifies the VM stays in a good state.
          states_thr = Thread.new do
            Thread.current[:result] = true

            # Otherwise, periodically verify the VM isn't in a bad state.
            while true
              state = env[:machine].state.id

              # Used to report invalid states
              Thread.current[:last_known_state] = state

              # Check if we have the proper state so we can break out
              if @states && !@states.include?(state)
                Thread.current[:result] = false
                break
              end

              # Sleep a bit so we don't hit 100% CPU constantly.
              sleep 1
            end
          end

          # Wait for a result or an interrupt
          env[:ui].output(I18n.t("vagrant.boot_waiting"))
          while ready_thr.alive? && states_thr.alive?
            sleep 1
            return if env[:interrupted]
          end

          # Join so that they can raise exceptions if there were any
          ready_thr.join if !ready_thr.alive?
          states_thr.join if !states_thr.alive?

          # If it went into a bad state, then raise an error
          if !states_thr[:result]
            raise Errors::VMBootBadState,
              valid: @states.join(", "),
              invalid: states_thr[:last_known_state]
          end

          # If it didn't boot, raise an error
          if !ready_thr[:result]
            raise Errors::VMBootTimeout
          end

          env[:ui].output(I18n.t("vagrant.boot_completed"))

          # Make sure our threads are all killed
          ready_thr.kill
          states_thr.kill

          @app.call(env)
        ensure
          ready_thr.kill
          states_thr.kill
        end
      end
    end
  end
end
