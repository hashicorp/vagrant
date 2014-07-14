module VagrantPlugins
  module HostArch
    module Cap
      class NFS
        def self.nfs_check_command(env)
          if systemd?
            return "/usr/sbin/systemctl status nfs-server"
          else
            return "/etc/rc.d/nfs-server status"
          end
        end

        def self.nfs_start_command(env)
          if systemd?
            return "/usr/sbin/systemctl start nfs-server"
          else
            return "/etc/rc.d/nfs-server start"
          end
        end

        def self.nfs_installed(environment)
          Kernel.system("grep -Fq nfs /proc/filesystems")
        end

        protected

        # This tests to see if systemd is used on the system. This is used
        # in newer versions of Arch, and requires a change in behavior.
        def self.systemd?
          `ps -o comm= 1`.chomp == 'systemd'
        end
      end
    end
  end
end
