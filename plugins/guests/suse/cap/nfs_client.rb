module VagrantPlugins
  module GuestSUSE
    module Cap
      class NFSClient
        def self.nfs_client_install(machine)
          machine.communicate.tap do |comm|
            comm.sudo("zypper -n install nfs-client")

            comm.sudo("/sbin/service rpcbind restart")
            comm.sudo("/sbin/service nfs restart")
          end
        end
      end
    end
  end
end
