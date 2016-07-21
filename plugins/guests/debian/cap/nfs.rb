module VagrantPlugins
  module GuestDebian
    module Cap
      class NFS
        def self.nfs_client_install(machine)
          comm = machine.communicate
          comm.sudo <<-EOH.gsub(/^ {12}/, '')
            set -e
            apt-get -yqq update
            apt-get -yqq install nfs-common portmap
          EOH
        end
      end
    end
  end
end
