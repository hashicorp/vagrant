require_relative "../facts"
require_relative "../pip/pip"

module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module Fedora
          module AnsibleInstall

            def self.ansible_install(machine, install_mode, ansible_version)
              rpm_package_manager = Facts::rpm_package_manager(machine)

              if install_mode == :pip
                pip_setup machine
                Pip::pip_install machine, "ansible", ansible_version
              else
                machine.communicate.sudo "#{rpm_package_manager} -y install ansible"
              end
            end

            private

            def self.pip_setup(machine)
              rpm_package_manager = Facts::rpm_package_manager(machine)

              machine.communicate.sudo "#{rpm_package_manager} install -y curl gcc gmp-devel libffi-devel openssl-devel python-crypto python-devel python-dnf python-setuptools redhat-rpm-config"
              Pip::get_pip machine
            end

          end
        end
      end
    end
  end
end
