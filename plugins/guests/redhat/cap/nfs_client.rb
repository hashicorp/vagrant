module VagrantPlugins
  module GuestRedHat
    module Cap
      class NFSClient
        def self.nfs_client_install(machine)
          machine.communicate.tap do |comm|
            comm.sudo("yum -y install nfs-utils nfs-utils-lib avahi")
            comm.sudo("/etc/init.d/rpcbind restart; /etc/init.d/nfs restart")
          end
        end
      end
    end
  end
end
