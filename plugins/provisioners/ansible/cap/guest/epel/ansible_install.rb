
module VagrantPlugins
  module Ansible
    module Cap
      module Guest
        module EPEL # Extra Packages for Enterprise Linux (for RedHat-family distributions)
          module AnsibleInstall

            # This should work on recent Fedora releases, and any other members of the
            # RedHat family which supports YUM and http://fedoraproject.org/wiki/EPEL
            def self.ansible_install(machine)

              configure_epel = <<INLINE_CRIPT
cat <<EOM >/etc/yum.repos.d/epel-bootstrap.repo
[epel]
name=Bootstrap EPEL
mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=epel-\$releasever&arch=\$basearch
failovermethod=priority
enabled=0
gpgcheck=0
EOM

yum --assumeyes --quiet --enablerepo=epel install epel-release
rm -f /etc/yum.repos.d/epel-bootstrap.repo
INLINE_CRIPT

              ansible_is_installable = machine.communicate.execute("yum info ansible", :error_check => false)
              if ansible_is_installable != 0
                machine.communicate.sudo(configure_epel)
              end
              machine.communicate.sudo("yum --assumeyes --quiet --enablerepo=epel install ansible")
            end

          end
        end
      end
    end
  end
end
