require 'log4r'

module VagrantPlugins
  module DockerProvider
    module Action
      class DestroyNetwork

        @@lock = Mutex.new

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

          @@lock.synchronize do
            machine.env.lock("docker-network-destroy", retry: true) do
              machine.config.vm.networks.each do |type, options|
                next if type != :private_network && type != :public_network

                vagrant_networks = machine.provider.driver.list_network_names.find_all do |n|
                  n.start_with?("vagrant_network")
                end

                vagrant_networks.each do |network_name|
                  if machine.provider.driver.existing_named_network?(network_name) &&
                      !machine.provider.driver.network_used?(network_name)
                    env[:ui].info(I18n.t("docker_provider.network_destroy", network_name: network_name))
                    machine.provider.driver.rm_network(network_name)
                  else
                    @logger.debug("Network #{network_name} not found or in use")
                  end
                end
              end
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
