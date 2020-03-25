module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Redhat
        module DockerInstall
          def self.docker_install(machine)
            machine.communicate.tap do |comm|
              comm.sudo("yum -q -y update")
              comm.sudo("yum -q -y remove docker-io* || true")
              if machine.guest.capability("flavor") == :rhel_8
                # containerd.io is not available on official yum repos
                # install it directly from docker
                comm.sudo("yum -y install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm")
              end
              comm.sudo("curl -fsSL https://get.docker.com/ | sh")
            end

            case machine.guest.capability("flavor")
            when :rhel_7
              docker_enable_rhel7(machine)
            else
              docker_enable_default(machine)
            end
          end

          def self.docker_enable_rhel7(machine)
            machine.communicate.tap do |comm|
              comm.sudo("systemctl start docker.service")
              comm.sudo("systemctl enable docker.service")
            end
          end

          def self.docker_enable_default(machine)
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
