module Vagrant
  module Action
    module VM
      class Halt
        def initialize(app, env, options=nil)
          @app = app
          env.merge!(options || {})
        end

        def call(env)
          if env[:vm].state == :running
            if !env["force"]
              env[:ui].info I18n.t("vagrant.actions.vm.halt.graceful")
              env[:vm].guest.halt
            end

            if env[:vm].state != :poweroff
              env[:ui].info I18n.t("vagrant.actions.vm.halt.force")
              env[:vm].driver.halt
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
