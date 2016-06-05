module VagrantPlugins
  module GuestRedHat
    module Cap
      class NFSClient
        def self.nfs_client_install(machine)
          machine.communicate.sudo <<-EOH.gsub(/^ {12}/, '')
            if command -v dnf; then
              dnf -y install nfs-utils nfs-utils-lib portmap
            else
              yum -y install nfs-utils nfs-utils-lib portmap
            fi

            if test $(ps -o comm= 1) == 'systemd'; then
              /bin/systemctl restart rpcbind nfs
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
