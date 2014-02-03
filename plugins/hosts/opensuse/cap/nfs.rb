module VagrantPlugins
  module HostOpenSUSE
    module Cap
      class NFS
        def self.nfs_check_command(env)
          "/sbin/service nfsserver status"
        end

        def self.nfs_start_command(env)
          "/sbin/service nfsserver start"
        end
      end
    end
  end
end
