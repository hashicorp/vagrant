
module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module Arch
          module AnsibleInstall

            def self.ansible_install(machine)
              machine.communicate.sudo("pacman -Syy --noconfirm")
              machine.communicate.sudo("pacman -S --noconfirm ansible")
            end

          end
        end
      end
    end
  end
end
