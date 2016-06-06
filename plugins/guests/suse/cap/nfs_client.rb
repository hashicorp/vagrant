module VagrantPlugins
  module GuestSUSE
    module Cap
      class NFSClient
        def self.nfs_client_install(machine)
          machine.communicate.sudo <<-EOH.gsub(/^ {12}/, '')
            zypper -n install nfs-client
            /sbin/service rpcbind restart
            /sbin/service nfs restart
          EOH
        end
      end
    end
  end
end
