module VagrantPlugins
  module HostSUSE
    module Cap
      class NFS
        def self.nfs_installed(env)
          system("rpm -q nfs-kernel-server > /dev/null 2>&1")
        end

        def self.nfs_check_command(env)
          "/usr/bin/systemctl --no-pager status nfsserver.service"
        end

        def self.nfs_start_command(env)
          "/usr/bin/systemctl --no-pager start nfsserver.service"
        end
      end
    end
  end
end
