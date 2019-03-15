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
        def generate_create_cli_arguments(options)
          cli_opts = []
          ignored_options = ["ip", "protocol", "id", "alias"].map(&:freeze).freeze

          # Splits the networking options to generate the proper CLI flags for docker
          options.each do |opt, value|
            opt = opt.to_s
            if (opt == "type" && value == "dhcp") || ignored_options.include?(opt)
              # `docker network create` doesn't care about these options
              next
            else
              cli_opts.concat(["--#{opt}=#{value.to_s}"])
            end
          end

          return cli_opts
        end

        # @param[Hash] options - options from the network config
        # @returns[Array] cli_opts - an array of strings used for the network commnad
        def generate_connect_cli_arguments(options)
          cli_opts = []

          if options[:ip]
            cli_opts = ["--ip", options[:ip]]
          elsif options[:ip6]
            cli_opts = ["--ip6", options[:ip6]]
          end

          if options[:alias]
            cli_opts.concat(["--alias=#{options[:alias]}"])
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

          env[:ui].info(I18n.t("docker_provider.network_configure"))

          machine.config.vm.networks.each do |type, options|
            # We only handle private networks
            next if type != :private_network

            cli_opts = generate_create_cli_arguments(options)

            if options[:subnet]
              existing_network = machine.provider.driver.subnet_defined?(options[:subnet])
              if !existing_network
                network_name = "vagrant_network_#{options[:subnet]}"
              else
                env[:ui].warn(I18n.t("docker_provider.subnet_exists",
                                     network_name: existing_network,
                                     subnet: options[:subnet]))
                network_name = existing_network
              end
            elsif options[:type] == "dhcp"
              network_name = "vagrant_network"
            else
              raise Errors::NetworkInvalidOption, container: machine.name
            end
            container_id = machine.id

            machine.env.lock("docker-network-create", retry: true) do
              if !machine.provider.driver.existing_network?(network_name)
                @logger.debug("Creating network #{network_name}")
                machine.provider.driver.create_network(network_name, cli_opts)
              else
                @logger.debug("Network #{network_name} already created")
              end
            end

            @logger.debug("Connecting network #{network_name} to container guest #{machine.name}")
            connect_opts = generate_connect_cli_arguments(options)
            machine.provider.driver.connect_network(network_name, container_id, connect_opts)
          end

          @app.call(env)
        end
      end
    end
  end
end
