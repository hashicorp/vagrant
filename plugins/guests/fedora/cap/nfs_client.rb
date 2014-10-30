module VagrantPlugins
  module GuestFedora
    module Cap
      class NFSClient
        def self.nfs_client_install(machine)
          machine.communicate.tap do |comm|
            comm.sudo("yum -y install nfs-utils nfs-utils-lib")
          end
        end
      end
    end
  end
end
