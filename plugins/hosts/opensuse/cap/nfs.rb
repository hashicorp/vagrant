module VagrantPlugins
  module HostOpenSUSE
    module Cap
      class NFS
        def self.nfs_check_command(_env)
          '/sbin/service nfsserver status'
        end

        def self.nfs_start_command(_env)
          '/sbin/service nfsserver start'
        end
      end
    end
  end
end
