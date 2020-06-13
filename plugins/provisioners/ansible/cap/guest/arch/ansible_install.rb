require_relative "../../../errors"
require_relative "../pip/pip"

module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module Arch
          module AnsibleInstall

            def self.ansible_install(machine, install_mode, ansible_version, pip_args, pip_install_cmd = "")
              case install_mode
              when :pip
                pip_setup machine, pip_install_cmd
                Pip::pip_install machine, "ansible", ansible_version, pip_args, true

              when :pip_args_only
                pip_setup machine, pip_install_cmd
                Pip::pip_install machine, "", "", pip_args, false

              else
                machine.communicate.sudo "pacman -Syy --noconfirm"
                machine.communicate.sudo "pacman -S --noconfirm ansible"
              end
            end

            private

            def self.pip_setup(machine, pip_install_cmd = "")
              machine.communicate.sudo "pacman -Syy --noconfirm"
              machine.communicate.sudo "pacman -S --noconfirm base-devel curl git python"

              Pip::get_pip machine, pip_install_cmd
            end

          end
        end
      end
    end
  end
end
