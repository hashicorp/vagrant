
module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module SUSE
          module AnsibleInstall

            def self.ansible_install(machine)
              machine.communicate.sudo("zypper --non-interactive --quiet install ansible")
            end

          end
        end
      end
    end
  end
end
