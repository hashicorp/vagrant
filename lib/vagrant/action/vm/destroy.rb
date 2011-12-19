module Vagrant
  module Action
    module VM
      class Destroy
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info I18n.t("vagrant.actions.vm.destroy.destroying")
          env[:vm].driver.delete
          env[:vm].uuid = nil

          @app.call(env)
        end
      end
    end
  end
end
