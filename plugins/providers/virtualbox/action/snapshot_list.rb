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

          @app.call(env)
        end
      end
    end
  end
end
