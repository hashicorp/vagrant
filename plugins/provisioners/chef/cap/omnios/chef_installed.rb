module VagrantPlugins
  module Chef
    module Cap
      module OmniOS
        module ChefInstalled
          # TODO: this is the same code as cap/linux/chef_installed, consider merging
          # Check if Chef is installed at the given version.
          # @return [true, false]
          def self.chef_installed(machine, product, version)
            verify_bin =  case product
                          when 'chef-workstation' then 'chef'
                          when 'cinc-workstation' then 'cinc'
                          when 'cinc' then 'cinc-client'
                          else 'chef-client'
                          end

            verify_path = "/opt/#{product}/bin/#{verify_bin}"
            command = "test -x #{verify_path}"

            if version != :latest
              command << "&& #{verify_path} --version | grep '#{version}'"
            end

            machine.communicate.test(command, sudo: true)
          end
        end
      end
    end
  end
end
