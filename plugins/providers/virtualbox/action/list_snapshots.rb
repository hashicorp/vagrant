# coding: utf-8
module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class ListSnapshots
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env
          
          # List all of the snapshots for the machine.
          env[:ui].info I18n.t("vagrant.actions.vm.snapshot.listing")          
          env[:machine].provider.driver.list_snapshots

          @app.call(env)
        end
      end
    end
  end
end
