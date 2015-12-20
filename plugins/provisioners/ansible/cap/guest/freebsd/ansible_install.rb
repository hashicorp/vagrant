
module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module FreeBSD
          module AnsibleInstall

            def self.ansible_install(machine)
              machine.communicate.sudo("yes | pkg install ansible")
            end

          end
        end
      end
    end
  end
end
