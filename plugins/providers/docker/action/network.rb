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

          env[:ui].info("Configuring and enabling network interfaces...")

          machine.config.vm.networks.each do |type, options|
            # We only handle private and public networks
            next if type != :private_network && type != :public_network

            # Look at docker provider config for network options:
            # - If not defined, create simple "folder environment" multi-network
            #   that all containers with this default option are attached to
            # - If provider config option is defined, create the requested network
            #   and attach that container to it
            connect_cli_opts = []
            create_cli_opts = []

            # make this a function that generates the proper flags
            if options[:type] != "dhcp"
              if options[:subnet]
                create_cli_opts.concat(["--subnet", options[:subnet]])
              end

              if options[:ip]
                connect_cli_opts.concat(["--ip", options[:ip]])
              end
            end

            network_name = "#{env[:root_path].basename.to_s}_network_#{machine.name}"
            container_id = machine.id
            # TODO: Need to check if network already exists and not error
            if !machine.provider.driver.existing_network?(network_name)
              @logger.debug("Creating network #{network_name}")
              machine.provider.driver.create_network(network_name, create_cli_opts)
            else
              @logger.debug("Network #{network_name} already created")
            end
            @logger.debug("Connecting network #{network_name} to container guest #{machine.name}")
            machine.provider.driver.connect_network(network_name, container_id, connect_cli_opts)
          end

          @app.call(env)
        end
      end
    end
  end
end
