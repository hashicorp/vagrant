module VagrantPlugins
  module GuestSUSE
    module Cap
      class NFSClient
        def self.nfs_client_install(machine)
          machine.communicate.sudo <<-EOH.gsub(/^ {12}/, '')
            zypper -n install nfs-client
            /usr/bin/systemctl restart rpcbind
            /usr/bin/systemctl restart nfs-client.target
          EOH
        end
      end
    end
  end
end
