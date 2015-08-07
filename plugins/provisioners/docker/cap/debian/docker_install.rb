module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Debian
        module DockerInstall
          def self.docker_install(machine, version)
            package = 'docker-engine'
            package << "-#{version}" if version != :latest

            machine.communicate.tap do |comm|
              comm.sudo("apt-get update -y")
              comm.sudo("apt-get install -y --force-yes -q curl")
              comm.sudo("apt-get purge -y lxc-docker*")
              comm.sudo("curl -sSL https://get.docker.com/ | sh")
            end
          end
        end
      end
    end
  end
end
