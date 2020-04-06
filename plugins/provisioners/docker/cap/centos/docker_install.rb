module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Centos
        module DockerInstall
          def self.docker_install(machine)
            machine.communicate.tap do |comm|
              comm.sudo("yum -q -y update")
              comm.sudo("yum -q -y remove docker-io* || true")
              comm.sudo("yum install -y -q yum-utils")
              comm.sudo("yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo")
              comm.sudo("yum makecache")
              comm.sudo("yum install -y -q docker-ce")
            end

            case machine.guest.capability("flavor")
            when :centos
              docker_enable_service(machine)
            else
              docker_enable_systemctl(machine)
            end
          end

          def self.docker_enable_systemctl(machine)
            machine.communicate.tap do |comm|
              comm.sudo("systemctl start docker.service")
              comm.sudo("systemctl enable docker.service")
            end
          end

          def self.docker_enable_service(machine)
            machine.communicate.tap do |comm|
              comm.sudo("service docker start")
              comm.sudo("chkconfig docker on")
            end
          end
        end
      end
    end
  end
end
