require_relative "../facts"
require_relative "../pip/pip"

module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module Alpine
          module AnsibleInstall

            DEV_PACKAGES = "python3-dev libffi-dev openssl-dev build-base".freeze

            def self.ansible_install(machine, install_mode, ansible_version, pip_args, pip_install_cmd = "")
              case install_mode
              when :pip
                pip_setup machine, pip_install_cmd
                Pip::pip_install machine, "ansible", ansible_version, pip_args, true
              when :pip_args_only
                pip_setup machine, pip_install_cmd
                Pip::pip_install machine, "", "", pip_args, false
              else
                ansible_apk_install machine
              end
            end

            private

            def self.ansible_apk_install(machine)
              machine.communicate.sudo "apk add --update python ansible"
            end

            def self.pip_setup(machine, pip_install_cmd = "")
              machine.communicate.sudo "apk add --update python3"
              machine.communicate.sudo "apk add --update #{DEV_PACKAGES}"
              machine.communicate.sudo "pip3 install --upgrade pip"
            end

          end
        end
      end
    end
  end
end
