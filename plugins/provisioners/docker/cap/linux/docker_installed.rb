module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Linux
        module DockerInstalled
          def self.docker_installed(machine)
            paths = [
              "/usr/bin/docker",
              "/usr/local/bin/docker",
              "/usr/sbin/docker",
            ]

            paths.each do |p|
              if machine.communicate.test("test -f #{p}", sudo: true)
                return true
              end
            end

            return false
          end
        end
      end
    end
  end
end
