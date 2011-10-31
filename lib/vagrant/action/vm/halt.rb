module Vagrant
  class Action
    module VM
      class Halt
        def initialize(app, env, options=nil)
          @app = app
          env.merge!(options || {})
        end

        def call(env)
          if env["vm"].created? && env["vm"].vm.running?
            begin
              env["vm"].system.halt if !env["force"]
            rescue
            end
            if env["vm"].vm.state(true) != :powered_off
              env.ui.info I18n.t("vagrant.actions.vm.halt.force")
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
