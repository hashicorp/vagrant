module VagrantPlugins
  module GuestDebian
    module Cap
      class NFSClient
        def self.nfs_client_install(machine)
          comm = machine.communicate
          comm.sudo <<-EOH.gsub(/^ {12}/, '')
            apt-get -yqq update
            apt-get -yqq install nfs-common portmap
          EOH
        end
      end
    end
  end
end
