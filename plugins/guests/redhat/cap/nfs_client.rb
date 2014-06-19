module VagrantPlugins
  module GuestRedHat
    module Cap
      class NFSClient
        def self.nfs_client_install(machine)
          machine.communicate.tap do |comm|
            comm.sudo("yum -y install nfs-utils nfs-utils-lib")
            comm.sudo("chkconfig rpcbind on")
            comm.sudo("service rpcbind start")
          end
        end
      end
    end
  end
end
