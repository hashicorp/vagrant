# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module GuestRedHat
    module Cap
      class NFSClient
        def self.nfs_client_install(machine)
          machine.communicate.sudo <<-EOH.gsub(/^ {12}/, '')
            if command -v dnf; then
              if `dnf info -q libnfs-utils > /dev/null 2>&1` ; then
                dnf -y install nfs-utils libnfs-utils portmap
              elif `dnf info -q nfs-utils-lib > /dev/null 2>&1` ; then
                dnf -y install nfs-utils nfs-utils-lib portmap
              else
                dnf -y install nfs-utils portmap
              fi
            else
              yum -y install nfs-utils nfs-utils-lib portmap
            fi

            if test $(ps -o comm= 1) == 'systemd'; then
              /bin/systemctl restart rpcbind nfs-server
            else
              /etc/init.d/rpcbind restart
              /etc/init.d/nfs restart
            fi
          EOH
        end
      end
    end
  end
end
