require 'log4r'

module VagrantPlugins
  module DockerProvider
    module Action
      class Network
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

            # Look at docker provider config for network options:
            # - If not defined, create simple "folder environment" multi-network
            #   that all containers with this default option are attached to
            # - If provider config option is defined, create the requested network
            #   and attach that container to it
            network_name = "#{env[:root_path].basename.to_s}_network_#{machine.name}"
            container_id = machine.id
            # TODO: Need to check if network already exists and not error
            machine.provider.driver.create_network(network_name)
            options = ["--ip", options[:ip]]
            machine.provider.driver.connect_network(network_name, container_id, options)
          end

          @app.call(env)
        end
      end
    end
  end
end
