module VagrantPlugins
  module GuestDebian
    module Cap
      class NFSClient
        def self.nfs_client_install(machine)
          machine.communicate.tap do |comm|
            comm.sudo("apt-get -y update")
            comm.sudo("apt-get -y install nfs-common portmap")
          end
        end
      end
    end
  end
end
