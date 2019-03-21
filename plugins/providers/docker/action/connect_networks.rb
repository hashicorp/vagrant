require 'ipaddr'
require 'log4r'

require 'vagrant/util/scoped_hash_override'

module VagrantPlugins
  module DockerProvider
    module Action
      class ConnectNetworks

        include Vagrant::Util::ScopedHashOverride

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant::plugins::docker::connectnetworks')
        end

        # Generate CLI arguments for creating the docker network.
        #
        # @param [Hash] options Options from the network config
        # @returns[Array<String> Network create arguments
        def generate_connect_cli_arguments(options)
          options.map do |key, value|
            # If value is false, option is not set
            next if value.to_s == "false"
            # If value is true, consider feature flag with no value
            opt = value.to_s == "true" ? [] : [value]
            opt.unshift("--#{key.to_s.tr("_", "-")}")
          end.flatten.compact
        end

        # Execute the action
        def call(env)
          # If we are using a host VM, then don't worry about it
          machine = env[:machine]
          if machine.provider.host_vm?
            @logger.debug("Not setting up networks because docker host_vm is in use")
            return @app.call(env)
          end

          env[:ui].info(I18n.t("docker_provider.network_connect"))

          connections = env[:docker_connects] || {}

          machine.config.vm.networks.each_with_index do |args, idx|
            type, options = args
            next if type != :private_network && type != :public_network

            network_options = scoped_hash_override(options, :docker_connect)
            network_options.delete_if{|k,_| options.key?(k)}
            network_name = connections[idx]

            if !network_name
              raise Errors::NetworkNameMissing,
                index: idx,
                container: machine.name
            end

            @logger.debug("Connecting network #{network_name} to container guest #{machine.name}")
            if options[:ip] && options[:type] != "dhcp"
              if IPAddr.new(options[:ip]).ipv4?
                network_options[:ip] = options[:ip]
              else
                network_options[:ip6] = options[:ip]
              end
            end
            network_options[:alias] = options[:alias] if options[:alias]
            connect_opts = generate_connect_cli_arguments(network_options)
            machine.provider.driver.connect_network(network_name, machine.id, connect_opts)
          end

          @app.call(env)
        end
      end
    end
  end
end
