module VagrantPlugins
  module HostSlackware
    module Cap
      class NFS
        def self.nfs_check_command(_env)
          'pidof nfsd >/dev/null'
        end

        def self.nfs_start_command(_env)
          '/etc/rc.d/rc.nfsd start'
        end
      end
    end
  end
end
