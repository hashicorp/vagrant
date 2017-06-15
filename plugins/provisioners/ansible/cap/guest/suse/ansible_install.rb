
module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module SUSE
          module AnsibleInstall

            def self.ansible_install(machine, install_mode, ansible_version, pip_args)
              if install_mode != :default
                raise Ansible::Errors::AnsiblePipInstallIsNotSupported
              else
                machine.communicate.sudo("zypper --non-interactive --quiet install ansible")
              end
            end

          end
        end
      end
    end
  end
end
