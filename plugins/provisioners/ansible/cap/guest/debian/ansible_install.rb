require_relative "../pip/pip"

module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module Debian
          module AnsibleInstall


            def self.ansible_install(machine, install_mode, ansible_version, pip_args)
              case install_mode
              when :pip
                pip_setup machine
                Pip::pip_install machine, "ansible", ansible_version, pip_args, true
              when :pip_args_only
                pip_setup machine
                Pip::pip_install machine, "", "", pip_args, false
              else
                ansible_apt_install machine
              end
            end

            private

            def self.ansible_apt_install(machine)
install_backports_if_wheezy_release = <<INLINE_CRIPT
CODENAME=`lsb_release -cs`
if [ x$CODENAME == 'xwheezy' ]; then
  echo 'deb http://http.debian.net/debian wheezy-backports main' > /etc/apt/sources.list.d/wheezy-backports.list
fi
INLINE_CRIPT

              machine.communicate.sudo install_backports_if_wheezy_release
              machine.communicate.sudo "apt-get update -y -qq"
              machine.communicate.sudo "apt-get install -y -qq ansible"
            end

            def self.pip_setup(machine)
              machine.communicate.sudo "apt-get update -y -qq"
              machine.communicate.sudo "apt-get install -y -qq build-essential curl git libssl-dev libffi-dev python-dev"
              Pip::get_pip machine
            end

          end
        end
      end
    end
  end
end
