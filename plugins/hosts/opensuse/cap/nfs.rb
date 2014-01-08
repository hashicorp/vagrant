module VagrantPlugins
  module HostOpenSUSE
    module Cap
      class NFS
        def self.nfs_check_command(env)
          "service nfsserver status"
        end

        def self.nfs_start_command(env)
          "service nfsserver start"
        end
      end
    end
  end
end
