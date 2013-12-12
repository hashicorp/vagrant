# coding: utf-8
module VagrantPlugins
  module CommandSnapshot
    module Action
      class RestoreSnapshot
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env
          
          # Take a snapshot of the machine.
          env[:ui].info I18n.t('vagrant.actions.vm.snapshot.restoring', 
                              :name => env[:machine].box.name)          
          env[:machine].provider.driver.restore_snapshot(env[:snapshot_name])

          @app.call(env)
        end
      end
    end
  end
end
