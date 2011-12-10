module Vagrant
  module Action
    module VM
      class Destroy
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info I18n.t("vagrant.actions.vm.destroy.destroying")
          env[:vm].vm.destroy
          env[:vm].vm = nil

          @app.call(env)
        end
      end
    end
  end
end
