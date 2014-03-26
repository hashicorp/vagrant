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
              if ! comm.test("rpm -qa | grep epel-release")
                comm.sudo("rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm")
              end
              comm.sudo("yum -y upgrade")
              comm.sudo("yum -y install docker-io")
            end
          end
        end
      end
    end
  end
end
