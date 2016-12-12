require_relative "../../../errors"

module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module Arch
          module AnsibleInstall

            def self.ansible_install(machine, install_mode, ansible_version)
              if install_mode == :pip
                raise Ansible::Errors::AnsiblePipInstallIsNotSupported
              else
                machine.communicate.sudo "pacman -Syy --noconfirm"
                machine.communicate.sudo "pacman -S --noconfirm ansible"
              end
            end

          end
        end
      end
    end
  end
end
