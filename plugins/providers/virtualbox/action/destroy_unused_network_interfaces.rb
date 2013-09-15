require "log4r"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class DestroyUnusedNetworkInterfaces
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::plugins::virtualbox::destroy_unused_netifs")
        end

        def call(env)
          if env[:machine].provider_config.destroy_unused_network_interfaces
            @logger.info("Destroying unused network interfaces...")
            env[:machine].provider.driver.delete_unused_host_only_networks
          end

          @app.call(env)
        end
      end
    end
  end
end
