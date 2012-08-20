module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class DestroyUnusedNetworkInterfaces
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:machine].provider.driver.delete_unused_host_only_networks
          @app.call(env)
        end
      end
    end
  end
end
