module VagrantPlugins
  module GuestGentoo
    module Cap
      class NFS
        def self.nfs_client_install(machine)
          comm = machine.communicate
          comm.sudo <<-EOH.gsub(/^ {12}/, '')
            emerge nfs-utils
            exit $?
          EOH
        end
      end
    end
  end
end
