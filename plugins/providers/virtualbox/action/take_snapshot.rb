# coding: utf-8
module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class TakeSnapshot
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env
          
          # Take a snapshot of the machine.
          env[:ui].info I18n.t('vagrant.actions.vm.snapshot.taking', 
                              :name => env[:machine].box.name)          
          env[:machine].provider.driver.take_snapshot()

          @app.call(env)
        end
      end
    end
  end
end
