module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Redhat
        module DockerInstall
          def self.docker_install(machine, version)
            if version != :latest
              machine.ui.warn(I18n.t("vagrant.docker_install_with_version_not_supported"))
            end

            machine.communicate.tap do |comm|
              comm.sudo("yum -y update")
              comm.sudo("yum -y remove docker-io*")
              comm.sudo("curl -sSL https://get.docker.com/ | sh")
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
