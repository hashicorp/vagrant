module VagrantPlugins
  module PodmanProvisioner
    module Cap
      module Linux
        module PodmanInstalled
          def self.podman_installed(machine)
            paths = [
              "/bin/podman",
              "/usr/bin/podman",
              "/usr/local/bin/podman",
              "/usr/sbin/podman",
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
