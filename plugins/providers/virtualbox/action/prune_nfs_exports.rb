module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class PruneNFSExports
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:host]
            valid_ids = env[:machine].provider.driver.read_vms
            env[:host].nfs_prune(valid_ids)
          end

          @app.call(env)
        end
      end
    end
  end
end
