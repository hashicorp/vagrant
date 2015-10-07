module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class SnapshotRestore
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t(
            "vagrant.actions.vm.snapshot.restoring",
            name: env[:snapshot_name]))
          env[:machine].provider.driver.restore_snapshot(
            env[:machine].id, env[:snapshot_name])

          @app.call(env)
        end
      end
    end
  end
end
