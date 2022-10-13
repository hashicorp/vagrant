module VagrantPlugins
  module DockerProvider
    module Cap
      module HasCommunicator
        def self.has_communicator(machine)
          return machine.provider_config.has_ssh
        end
      end
    end
  end
end
