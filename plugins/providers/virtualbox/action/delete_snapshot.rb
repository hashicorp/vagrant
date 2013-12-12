# coding: utf-8
module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class DeleteSnapshot
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env
          
          # Take a snapshot of the machine.
          env[:ui].info I18n.t("vagrant.actions.vm.snapshot.deleting")          

          @app.call(env)
        end
      end
    end
  end
end
