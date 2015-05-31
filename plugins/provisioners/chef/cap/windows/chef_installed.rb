module VagrantPlugins
  module Chef
    module Cap
      module Windows
        module ChefInstalled
          # Check if Chef is installed at the given version.
          # @return [true, false]
          def self.chef_installed(machine, version)
            if version != :latest
              command = 'if ((&knife --version) -Match "Chef: "' + version + '"){ exit 0 } else { exit 1 }'
            else
              command = 'if ((&knife --version) -Match "Chef: *"){ exit 0 } else { exit 1 }'
            end
            machine.communicate.test(command, sudo: true)
          end
        end
      end
    end
  end
end
