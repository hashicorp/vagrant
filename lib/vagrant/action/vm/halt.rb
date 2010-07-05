module Vagrant
  class Action
    module VM
      class Halt
        def initialize(app, env)
          @app = app
        end

        def call(env)
          return env.error!(:vm_not_running) unless env["vm"].vm.running?

          env["vm"].system.halt if !env["force"]

          if env["vm"].vm.state(true) != :powered_off
            env.logger.info "Forcing shutdown of VM..."
            env["vm"].vm.stop
          end

          @app.call(env)
        end
      end
    end
  end
end
