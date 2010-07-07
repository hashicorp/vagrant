module Vagrant
  class Action
    module VM
      class Customize
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if !env.env.config.vm.proc_stack.empty?
            env.logger.info "Running any VM customizations..."
            env.env.config.vm.run_procs!(env["vm"].vm)
            env["vm"].vm.save
          end

          @app.call(env)
        end
      end
    end
  end
end
