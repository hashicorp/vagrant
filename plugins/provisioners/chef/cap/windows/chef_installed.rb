module VagrantPlugins
  module Chef
    module Cap
      module Windows
        module ChefInstalled
          # Check if Chef is installed at the given version.
          # @return [true, false]
          def self.chef_installed(machine, product, version)
            verify_bin =  case product
                          when 'chef-workstation' then 'chef'
                          when 'cinc-workstation' then 'cinc'
                          when 'cinc' then 'cinc-client'
                          else 'chef-client'
                          end

            if version != :latest
              command = 'if ((&' + verify_bin + ' --version) -Match "' + version.to_s + '"){ exit 0 } else { exit 1 }'
            else
              command = 'if ((&' + verify_bin + ' --version) -Match "Chef*"){ exit 0 } else { exit 1 }'
            end
            machine.communicate.test(command, sudo: true)
          end
        end
      end
    end
  end
end
