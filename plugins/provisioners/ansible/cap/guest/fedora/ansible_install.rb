
module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module Fedora
          module AnsibleInstall

            def self.ansible_install(machine)
              if dnf?(machine)
                machine.communicate.sudo("dnf -y install ansible")
              else
                machine.communicate.sudo("yum -y install ansible")
              end
            end

            def self.dnf?(machine)
              machine.communicate.test("/usr/bin/which -s dnf")
            end

          end
        end
      end
    end
  end
end
