module VagrantPlugins
  module PodmanProvisioner
    module Cap
      module Linux
        module PodmanInstalled
          def self.podman_installed(machine)
            machine.communicate.test("command -v podman")
          end
        end
      end
    end
  end
end
