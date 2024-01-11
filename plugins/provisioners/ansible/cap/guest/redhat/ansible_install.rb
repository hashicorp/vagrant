# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require_relative "../facts"
require_relative "../pip/pip"

module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module RedHat
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
                ansible_rpm_install machine
              end
            end

            private

            def self.ansible_rpm_install(machine)
              rpm_package_manager = Facts::rpm_package_manager(machine)

              epel = machine.communicate.execute "#{rpm_package_manager} repolist epel | grep -q epel", error_check: false
              if epel != 0
                machine.communicate.sudo 'sudo rpm -i https://dl.fedoraproject.org/pub/epel/epel-release-latest-`rpm -E %dist | sed -n \'s/.*el\([0-9]\).*/\1/p\'`.noarch.rpm'
              end
              machine.communicate.sudo "#{rpm_package_manager} -y --enablerepo=epel install ansible"
            end

            def self.pip_setup(machine, pip_install_cmd = "")
              rpm_package_manager = Facts::rpm_package_manager(machine)

              # Use other packages for RHEL > 7 and set alternatives for RHEL 8
              machine.communicate.sudo(%Q{
                source /etc/os-release
                MAJOR=$(echo $VERSION_ID | cut -d. -f1)
                if [ $MAJOR -ge 8 ]; then
                  #{rpm_package_manager} -y install curl gcc libffi-devel openssl-devel python3-cryptography python3-devel python3-setuptools
                else
                  #{rpm_package_manager} -y install curl gcc libffi-devel openssl-devel python-crypto python-devel python-setuptools
                fi
                if [ $MAJOR -eq 8 ]; then
                  alternatives --set python /usr/bin/python3
                fi
              })

              # pip is already installed as dependency for RHEL > 7
              if machine.communicate.test("test ! -f /usr/bin/pip3")
                Pip::get_pip machine, pip_install_cmd
              end
              # Set pip-alternative for RHEL 8
              machine.communicate.sudo(%Q{
                source /etc/os-release
                MAJOR=$(echo $VERSION_ID | cut -d. -f1)
                if [ $MAJOR -eq 8 ]; then
                  alternatives --install /usr/bin/pip pip /usr/local/bin/pip 1
                fi
              })
            end

          end
        end
      end
    end
  end
end
