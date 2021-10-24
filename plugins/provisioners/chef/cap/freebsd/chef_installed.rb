module VagrantPlugins
  module Chef
    module Cap
      module FreeBSD
        module ChefInstalled
          # Check if Chef is installed at the given version.
          # @return [true, false]
          def self.chef_installed(machine, product, version)
            product_name = product == 'chef-workstation' ? 'chef-workstation' : 'chef'
            product_binary = product_name == 'chef-workstation' ? 'chef' : 'chef-client'
            test_binary = "/opt/#{product_name}/bin/#{product_binary}"
            command = "test -x #{test_binary}"

            if version != :latest
              command << "&& #{test_binary} --version | grep '#{version}'"
            end

            machine.communicate.test(command, sudo: true)
          end
        end
      end
    end
  end
end
