module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Redhat
        module DockerInstall
          def self.docker_install(machine, version)
            if version != :latest
              machine.ui.warn(I18n.t("vagrant.docker_install_with_version_not_supported"))
            end

            case machine.guest.capability("flavor")
            when :rhel_7
              docker_install_rhel7(machine)
            else
              docker_install_default(machine)
            end
          end

          def self.docker_install_rhel7(machine)
            machine.communicate.tap do |comm|
              comm.sudo("yum -y install docker")
              comm.sudo("systemctl start docker.service")
              comm.sudo("systemctl enable docker.service")
            end
          end

          def self.docker_install_default(machine)
            machine.communicate.tap do |comm|
              if ! comm.test("rpm -qa | grep epel-release")
                comm.sudo("rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm")
              end
              comm.sudo("yum -y install docker-io")
            end
          end
        end
      end
    end
  end
end
