require 'log4r'

module VagrantPlugins
  module DockerProvider
    module Action
      class DestroyNetwork
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant::plugins::docker::network')
        end

        def call(env)
          # If we are using a host VM, then don't worry about it
          machine = env[:machine]
          if machine.provider.host_vm?
            @logger.debug("Not setting up networks because docker host_vm is in use")
            return @app.call(env)
          end

          machine.config.vm.networks.each do |type, options|
            # We only handle private and public networks
            next if type != :private_network && type != :public_network

            # If network is defined in machines config as isolated single container network, then delete
            # If it's custom and or default, check if other containers are using it, and if not, delete
            network_name = "#{env[:root_path].basename.to_s}_network_#{machine.name}"

            if machine.provider.driver.existing_network?(network_name) &&
                !machine.provider.driver.network_used?(network_name)
              env[:ui].info("Removing network #{network_name}")
              machine.provider.driver.rm_network(network_name)
            else
              @logger.debug("Network #{network_name} not found")
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
