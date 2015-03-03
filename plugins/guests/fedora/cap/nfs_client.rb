module VagrantPlugins
  module GuestFedora
    module Cap
      class NFSClient
        def self.nfs_client_install(machine)
          machine.communicate.tap do |comm|
            comm.sudo("yum -y install nfs-utils nfs-utils-lib")
            case machine.guest.capability("flavor")
            when :f21
              comm.sudo("/bin/systemctl restart rpcbind nfs")
            else
              comm.sudo("/etc/init.d/rpcbind restart; /etc/init.d/nfs restart")
            end
          end
	end
      end
    end
  end
end

