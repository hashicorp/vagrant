module Vagrant
  class Action
    module VM
      class Halt
        include ExceptionCatcher

        def initialize(app, env, options=nil)
          @app = app
          env.merge!(options || {})
        end

        def call(env)
          if env["vm"].vm.running?
            if !env["force"]
              catch_action_exception(env) { env["vm"].system.halt }
              return if env.error?
            end

            if env["vm"].vm.state(true) != :powered_off
              env.logger.info "Forcing shutdown of VM..."
              env["vm"].vm.stop
            end

            # Sleep for a second to verify that the VM properly
            # cleans itself up
            sleep 1 if !env["vagrant.test"]
          end

          @app.call(env)
        end
      end
    end
  end
end
