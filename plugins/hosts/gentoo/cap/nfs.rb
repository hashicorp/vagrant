require "vagrant/util/subprocess"

module VagrantPlugins
  module HostGentoo
    module Cap
      class NFS
        def self.nfs_check_command(env)
          if systemd?
            return "/usr/bin/systemctl status nfsd"
          else
            return "/etc/init.d/nfs status"
          end
        end

        def self.nfs_start_command(env)
          if systemd?
            return "/usr/bin/systemctl start nfsd rpc-mountd rpcbind"
          else
            return "/etc/init.d/nfs restart"
          end
        end

        protected

        # This tests to see if systemd is used on the system. This is used
        # in newer versions of Arch, and requires a change in behavior.
        def self.systemd?
          result = Vagrant::Util::Subprocess.execute("ps", "-o", "comm=", "1")
          return result.stdout.chomp == "systemd"
        end
      end
    end
  end
end
