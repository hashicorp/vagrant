module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class SnapshotList
        def initialize(app, env)
          @app = app
        end

        def call(env)
          snapshots = env[:machine].provider.driver.list_snapshots(
            env[:machine].id)

          snapshots.each do |snapshot|
            env[:machine].ui.output(snapshot, prefix: false)
          end

          if snapshots.empty?
            env[:machine].ui.output(I18n.t("vagrant.actions.vm.snapshot.list_none"))
            env[:machine].ui.detail(I18n.t("vagrant.actions.vm.snapshot.list_none_detail"))
          end

          @app.call(env)
        end
      end
    end
  end
end
