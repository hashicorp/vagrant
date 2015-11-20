module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Fedora
        module DockerInstall
          def self.docker_install(machine)
            machine.communicate.tap do |comm|
              if dnf?(machine)
                comm.sudo("dnf -y install docker")
              else
                comm.sudo("yum -y install docker")
              end
              comm.sudo("systemctl start docker.service")
              comm.sudo("systemctl enable docker.service")
            end
          end

          protected

          def self.dnf?(machine)
            machine.communicate.test("/usr/bin/which -s dnf")
          end
        end
      end
    end
  end
end
