module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Centos
        module DockerStartService
          def self.docker_start_service(machine)
            case machine.guest.capability("flavor")
            when :centos
              machine.communicate.tap do |comm|
                comm.sudo("service docker start")
                comm.sudo("chkconfig docker on")
              end
            else
              machine.communicate.tap do |comm|
                comm.sudo("systemctl start docker.service")
                comm.sudo("systemctl enable docker.service")
              end
            end
          end
        end
      end
    end
  end
end
