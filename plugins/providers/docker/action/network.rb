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
          if env[:machine].provider.host_vm?
            @logger.debug("Not setting up networks because docker host_vm is in use")
            return @app.call(env)
          end

          env[:machine].config.vm.networks.each do |type, options|
            # We only handle private and public networks
            next if type != :private_network && type != :public_network

            # TODO: Configure and set up network for each container that has a network
            # machine.id == container id
            # docker network name == env[:machine].name + "_vagrant_" + unique-sha
          end

          @app.call(env)
        end
      end
    end
  end
end
