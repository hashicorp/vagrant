module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Debian
        module DockerInstall
          def self.docker_install(machine)
            machine.communicate.tap do |comm|
              comm.sudo("apt-get update -qq -y")
              comm.sudo("apt-get install -qq -y --force-yes curl apt-transport-https")
              comm.sudo("apt-get purge -qq -y lxc-docker* || true")
              comm.sudo("curl -sSL https://get.docker.com/ | sh")
            end
          end
        end
      end
    end
  end
end
