module VagrantPlugins
  module HostArch
    module Cap
      class NFS
        def self.nfs_check_command(env)
          return "/usr/sbin/systemctl status --no-pager nfs-server.service"
        end

        def self.nfs_start_command(env)
          return "/usr/sbin/systemctl start nfs-server.service"
        end

        def self.nfs_installed(environment)
          Kernel.system("systemctl --no-pager --no-legend --plain list-unit-files --all --type=service | grep --fixed-strings --quiet nfs-server.service")
        end
      end
    end
  end
end
