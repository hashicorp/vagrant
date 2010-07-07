module Vagrant
  class Action
    module VM
      class Suspend
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env["vm"].vm.running?
            env.logger.info "Saving VM state and suspending execution..."
            env["vm"].vm.save_state
          end

          @app.call(env)
        end
      end
    end
  end
end
