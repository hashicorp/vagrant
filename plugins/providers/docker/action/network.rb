require 'log4r'

module VagrantPlugins
  module DockerProvider
    module Action
      class Network
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant::plugins::docker::network')
        end

        # TODO: This is not ideal, but not enitrely sure a good way
        # around this without either having separate config options (which is worse for the user)
        # or forcing them to care about options for each separate docker network command (which is also
        # not great for the user). Basically a user wants to say:
        #
        # config.vm.network :private_network, <config options>
        #
        # We could limit the options to be name spaced simply `docker__option` like
        #
        # config.vm.network :private_network, docker__ip: "ip here"
        #
        # But then we will need this method to split out each option for creating and connecting networks
        #
        # Alternatively we could do
        #
        # - `docker__create__option`
        # - `docker__connect__option`
        # - ...etc...
        #
        # config.vm.network :private_network, docker__connect__ip: "ip here",
        #                                     docker__create__subnet: "subnet"
        #
        # But this will force users to care about what options are for which commands,
        # but maybe they will have to care about it anyway, and it isn't that big of
        # a deal for the extra namespacing?
        #
        # Extra namespacing puts more effort on the user side, but would allow us
        # to be 'smarter' about how we set options in code by seeing essnetially
        # what command the flag/option is intended for, rather than us trying to keep
        # track of the commands/flags manually in this function.
        #
        # @param[Hash] options - options from the network config
        # @returns[Hash] cli_opts - an array of strings used for the network commnad
        def parse_cli_arguments(options)
          cli_opts = {create: [], connect: []}

          # make this a function that generates the proper flags
          if options[:type] != "dhcp"
            if options[:docker__subnet]
              cli_opts[:create].concat(["--subnet", options[:docker__subnet]])
            end

            if options[:docker__ip]
              cli_opts[:connect].concat(["--ip", options[:docker__ip]])
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
            # We only handle private and public networks
            next if type != :private_network && type != :public_network

            cli_opts = parse_cli_arguments(options)

            network_name = "#{env[:root_path].basename.to_s}_network_#{machine.name}"
            container_id = machine.id

            if !machine.provider.driver.existing_network?(network_name)
              @logger.debug("Creating network #{network_name}")
              machine.provider.driver.create_network(network_name, cli_opts[:create])
            else
              @logger.debug("Network #{network_name} already created")
            end

            @logger.debug("Connecting network #{network_name} to container guest #{machine.name}")
            machine.provider.driver.connect_network(network_name, container_id, cli_opts[:connect])
          end

          @app.call(env)
        end
      end
    end
  end
end
