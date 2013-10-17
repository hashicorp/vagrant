require "vagrant"
require "vagrant/util/subprocess"

require Vagrant.source_root.join("plugins/hosts/linux/host")

module VagrantPlugins
  module HostGentoo
    class Host < VagrantPlugins::HostLinux::Host
      def self.match?
        return File.exists?("/etc/gentoo-release")
      end

      # Normal, mid-range precedence.
      def self.precedence
        5
      end

      def initialize(*args)
        super

        @nfs_apply_command = "/usr/sbin/exportfs -r"
        if systemd?
          @nfs_check_command = "/usr/bin/systemctl status nfsd"
          @nfs_start_command = "/usr/bin/systemctl start nfsd rpc-mountd rpcbind"
        else
          @nfs_check_command = "/etc/init.d/nfs status"
          @nfs_start_command = "/etc/init.d/nfs start"
        end
      end

      protected

      # Check for systemd presence from current processes.
      def systemd?
        result = Vagrant::Util::Subprocess.execute("ps", "-o", "comm=", "1")
        return result.stdout.chomp == "systemd"
      end
    end
  end
end
