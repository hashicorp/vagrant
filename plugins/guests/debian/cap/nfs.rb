module VagrantPlugins
  module GuestDebian
    module Cap
      class NFS
        def self.nfs_client_install(machine)
          comm = machine.communicate
          comm.sudo <<-EOH.gsub(/^ {12}/, '')
            apt-get -yqq update
            apt-get -yqq install nfs-common portmap
            exit $?
          EOH
        end
      end
    end
  end
end
