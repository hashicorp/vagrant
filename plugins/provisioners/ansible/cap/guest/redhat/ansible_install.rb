require_relative "../facts"
require_relative "../pip/pip"

module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module RedHat
          module AnsibleInstall

            def self.ansible_install(machine, install_mode, ansible_version)
              if install_mode == :pip
                pip_setup machine
                Pip::pip_install machine, "ansible", ansible_version
              else
                ansible_rpm_install machine
              end
            end

            private

            def self.ansible_rpm_install(machine)
              epel = machine.communicate.execute "#{yum_dnf(machine)} repolist epel | grep -q epel", error_check: false
              if epel != 0
                machine.communicate.sudo 'sudo rpm -i https://dl.fedoraproject.org/pub/epel/epel-release-latest-`rpm -E %dist | sed -n \'s/.*el\([0-9]\).*/\1/p\'`.noarch.rpm'
              end

              machine.communicate.sudo "#{Facts::rpm_package_manager} -y --enablerepo=epel install ansible"
            end

            def self.pip_setup(machine)
              machine.communicate.sudo("#{Facts::rpm_package_manager(machine)} install -y curl gcc libffi-devel openssl-devel python-crypto python-devel python-setuptools")
              Pip::get_pip machine
            end

          end
        end
      end
    end
  end
end
