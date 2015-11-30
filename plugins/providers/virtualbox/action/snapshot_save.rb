module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class SnapshotSave
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t(
            "vagrant.actions.vm.snapshot.saving",
            name: env[:snapshot_name]))
          env[:machine].provider.driver.create_snapshot(
            env[:machine].id, env[:snapshot_name])

          env[:ui].success(I18n.t(
            "vagrant.actions.vm.snapshot.saved",
            name: env[:snapshot_name]))

          @app.call(env)
        end
      end
    end
  end
end
