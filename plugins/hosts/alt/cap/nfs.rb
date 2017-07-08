require "vagrant/util/subprocess"
require "vagrant/util/which"

module VagrantPlugins
  module HostALT
    module Cap
      class NFS
        def self.nfs_check_command(env)
          if systemd?
            return "systemctl status --no-pager nfs-server.service"
          else
            return "/etc/init.d/nfs status"
          end
        end

        def self.nfs_start_command(env)
          if systemd?
            return "systemctl start rpcbind nfs-server.service"
          else
            return "/etc/init.d/nfs restart"
          end
        end

        def self.nfs_installed(environment)
          if systemd?
            system("systemctl --no-pager --no-legend --plain list-unit-files --all --type=service | grep --fixed-strings --quiet nfs-server.service")
          else
            system("rpm -q nfs-server --quiet 2>&1")
          end
        end

        protected

        # This tests to see if systemd is used on the system. This is used
        # in newer versions of ALT, and requires a change in behavior.
        def self.systemd?
          result = Vagrant::Util::Subprocess.execute("ps", "-o", "comm=", "1")
          return result.stdout.chomp == "systemd"
        end
      end
    end
  end
end
