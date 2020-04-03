module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Redhat
        module DockerInstall
          def self.docker_install(machine)
            flavor = machine.guest.capability("flavor")
            if flavor.to_s.include? "rhel"
              # rhel is not supported by docker ce
              # https://docs.docker.com/ee/docker-ee/rhel/
              machine.ui.warn(I18n.t("vagrant.provisioners.docker.rhel_not_supported"))
              raise DockerError, :install_failed
            end

            machine.communicate.tap do |comm|
              comm.sudo("yum -q -y update")
              comm.sudo("yum -q -y remove docker-io* || true")
              comm.sudo("yum install -y -q yum-utils")
              comm.sudo("yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo")
              comm.sudo("yum makecache")
              comm.sudo("yum install -y -q docker-ce")
            end

            case flavor
            when :centos_7
              docker_enable_centos7(machine)
            else
              docker_enable_default(machine)
            end
          end

          def self.docker_enable_centos7(machine)
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
