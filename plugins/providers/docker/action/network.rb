require 'log4r'

module VagrantPlugins
  module DockerProvider
    module Action
      class Network
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant::plugins::docker::network')
        end

        # @param[Hash] options - options from the network config
        # @returns[Array] cli_opts - an array of strings used for the network commnad
        def generate_connect_cli_arguments(options)
          cli_opts = []

          # Splits the networking options to generate the proper CLI flags for docker
          options.each do |opt, value|
            opt = opt.to_s
            if opt == "ip" || (opt == "type" && value == "dhcp") ||
                opt == "protocol" || opt == "id"
              # `docker network create` doesn't care about these options
              next
            else
              cli_opts.concat(["--#{opt}", value])
            end
          end

          return cli_opts
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
            # We only handle private networks
            next if type != :private_network

            cli_opts = generate_connect_cli_arguments(options)

            if options[:subnet]
              network_name = "vagrant_network_#{options[:subnet]}"
            elsif options[:type] == "dhcp"
              network_name = "vagrant_network"
            else
              # TODO: Make this an error class
              raise "Must specify a `subnet` or use `dhcp`"
            end
            container_id = machine.id

            if !machine.provider.driver.existing_network?(network_name)
              @logger.debug("Creating network #{network_name}")
              machine.provider.driver.create_network(network_name, cli_opts)
            else
              @logger.debug("Network #{network_name} already created")
            end

            @logger.debug("Connecting network #{network_name} to container guest #{machine.name}")
            connect_opts = []
            if options[:ip]
              connect_opts = ["--ip", options[:ip]]
            elsif options[:ip6]
              connect_opts = ["--ip6", options[:ip6]]
            end
            machine.provider.driver.connect_network(network_name, container_id, connect_opts)
          end

          @app.call(env)
        end
      end
    end
  end
end
