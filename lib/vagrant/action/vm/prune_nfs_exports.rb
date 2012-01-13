module Vagrant
  module Action
    module VM
      class PruneNFSExports
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:host]
            valid_ids = env[:vm].driver.read_vms
            env[:host].nfs_prune(valid_ids)
          end

          @app.call(env)
        end
      end
    end
  end
end
