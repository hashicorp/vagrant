module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class SnapshotDelete
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t(
            "vagrant.actions.vm.snapshot.deleting",
            name: env[:snapshot_name]))
          env[:machine].provider.driver.delete_snapshot(
            env[:machine].id, env[:snapshot_name]) do |progress|
            env[:ui].clear_line
            env[:ui].report_progress(progress, 100, false)
          end

          # Clear the line one last time since the progress meter doesn't disappear
          # immediately.
          env[:ui].clear_line

          env[:ui].success(I18n.t(
            "vagrant.actions.vm.snapshot.deleted",
            name: env[:snapshot_name]))

          @app.call(env)
        end
      end
    end
  end
end
