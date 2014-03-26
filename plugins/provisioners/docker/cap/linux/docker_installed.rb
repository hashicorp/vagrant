module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Linux
        module DockerInstalled
          def self.docker_installed(machine)
            machine.communicate.test("test -f /usr/bin/docker", sudo: true)
          end
        end
      end
    end
  end
end
