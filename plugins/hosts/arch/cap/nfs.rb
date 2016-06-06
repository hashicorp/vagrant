module VagrantPlugins
  module HostArch
    module Cap
      class NFS
        def self.nfs_check_command(env)
            return "/usr/sbin/systemctl status nfs-server.service"
          end
        end

        def self.nfs_start_command(env)
            return "/usr/sbin/systemctl start nfs-server.service"
          end
        end

        def self.nfs_installed(environment)
          Kernel.system("grep -Fq nfsd /proc/filesystems")
        end
      end
    end
  end
end
