module Vagrant
  module Action
    module VM
      class Suspend
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:vm].state == :running
            env[:ui].info I18n.t("vagrant.actions.vm.suspend.suspending")
            env[:vm].driver.suspend
          end

          @app.call(env)
        end
      end
    end
  end
end
