module VagrantPlugins
  module HostSlackware
    module Cap
      class NFS
        def self.nfs_check_command(env)
          "/sbin/pidof nfsd >/dev/null"
        end

        def self.nfs_start_command(env)
          "/etc/rc.d/rc.nfsd start"
        end
      end
    end
  end
end
