module VagrantPlugins
  module HostSUSE
    module Cap
      class NFS
        def self.nfs_installed(env)
          system("rpm -q nfs-kernel-server > /dev/null 2>&1")
        end

        def self.nfs_check_command(env)
          "systemctl status --no-pager nfs-server"
        end

        def self.nfs_start_command(env)
          "systemctl start --no-pager nfs-server"
        end
      end
    end
  end
end
