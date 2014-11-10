module VagrantPlugins
  module Chef
    module Cap
      module Linux
        module ChefInstalled
          # Check if Chef is installed at the given version.
          # @return [true, false]
          def self.chef_installed(machine, version)
            knife = "/opt/chef/bin/knife"
            command = "test -x #{knife}"

            if version != :latest
              command << "&& #{knife} --version | grep 'Chef: #{version}'"
            end

            machine.communicate.test(command, sudo: true)
          end
        end
      end
    end
  end
end
