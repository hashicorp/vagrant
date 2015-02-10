
module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module Debian
          module AnsibleInstall

            def self.ansible_install(machine)

install_backports_if_wheezy_release = <<INLINE_CRIPT
CODENAME=`lsb_release -cs`
if [ x$CODENAME == 'xwheezy' ]; then
  echo 'deb http://http.debian.net/debian wheezy-backports main' > /etc/apt/sources.list.d/wheezy-backports.list
fi
INLINE_CRIPT

              machine.communicate.sudo(install_backports_if_wheezy_release)
              machine.communicate.sudo("apt-get update -y -qq")
              machine.communicate.sudo("apt-get install -y -qq ansible")
            end

          end
        end
      end
    end
  end
end
