module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Redhat
        module DockerStartService
          def self.docker_start_service(machine)
            machine.communicate.sudo("service docker start")
            # TODO :: waiting to start
            sleep 5
            machine.communicate.sudo("chkconfig docker on")
          end
        end
      end
    end
  end
end
