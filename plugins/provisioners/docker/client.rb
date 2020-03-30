require_relative "../container/client"

module VagrantPlugins
  module DockerProvisioner
    class Client < VagrantPlugins::ContainerProvisioner::Client
      def initialize(machine)
        super(machine, "docker")
        @container_command = "docker"
      end

      def start_service
        if !daemon_running? && @machine.guest.capability?(:docker_start_service)
          @machine.guest.capability(:docker_start_service)
        end
      end

      def daemon_running?
        @machine.guest.capability(:docker_daemon_running)
      end

    end
  end
end
