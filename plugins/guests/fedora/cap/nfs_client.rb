module VagrantPlugins
  module GuestFedora
    module Cap
      class NFSClient
        def self.nfs_client_install(machine)
          machine.communicate.sudo("yum -y install nfs-utils nfs-utils-lib")
          machine.communicate.sudo("/bin/systemctl restart rpcbind nfs")
        end
      end
    end
  end
end
