module VagrantPlugins
  module HostSUSE
    module Cap
      class NFS
        def self.nfs_check_command(env)
          "pidof nfsd > /dev/null"
        end

        def self.nfs_start_command(env)
          "/sbin/service nfsserver start"
        end
      end
    end
  end
end
