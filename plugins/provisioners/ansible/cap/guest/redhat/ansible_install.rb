
module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module RedHat
          module AnsibleInstall

            def self.ansible_install(machine)
              epel = machine.communicate.execute("#{yum_dnf(machine)} repolist epel | grep -q epel", :error_check => false)
              if epel != 0
                machine.communicate.sudo('sudo rpm -i https://dl.fedoraproject.org/pub/epel/epel-release-latest-`rpm -E %dist | sed -n \'s/.*el\([0-9]\).*/\1/p\'`.noarch.rpm')
              end

              machine.communicate.sudo("#{yum_dnf(machine)} -y --enablerepo=epel install ansible")
            end

            def self.yum_dnf(machine)
              machine.communicate.test("/usr/bin/which -s dnf") ? "dnf" : "yum"
            end

          end
        end
      end
    end
  end
end
