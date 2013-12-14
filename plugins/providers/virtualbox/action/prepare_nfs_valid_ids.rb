module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class PrepareNFSValidIds
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::action::vm::nfs")
        end

        def call(env)
          env[:nfs_valid_ids] = env[:machine].provider.driver.read_vms.values
          @app.call(env)
        end
      end
    end
  end
end
