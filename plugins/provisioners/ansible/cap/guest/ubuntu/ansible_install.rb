require_relative "../debian/ansible_install"

module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module Ubuntu
          module AnsibleInstall

            def self.ansible_install(machine, install_mode, ansible_version, pip_args, pip_install_cmd = "")
              if install_mode != :default
                Debian::AnsibleInstall::ansible_install machine, install_mode, ansible_version, pip_args, pip_install_cmd
              else
                ansible_apt_install machine
              end
            end

            private

            def self.ansible_apt_install(machine)
              unless machine.communicate.test("test -x \"$(which add-apt-repository)\"")
                machine.communicate.sudo """
                  apt-get update -y -qq && \
                  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq software-properties-common --option \"Dpkg::Options::=--force-confold\"
                """
              end
              machine.communicate.sudo """
                add-apt-repository ppa:ansible/ansible -y && \
                apt-get update -y -qq && \
                DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ansible --option \"Dpkg::Options::=--force-confold\"
              """
            end

          end
        end
      end
    end
  end
end
