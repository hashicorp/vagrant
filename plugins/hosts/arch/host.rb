require "vagrant"

require Vagrant.source_root.join("plugins/hosts/linux/host")

module VagrantPlugins
  module HostArch
    class Host < VagrantPlugins::HostLinux::Host
      def self.match?
        File.exist?("/etc/arch-release")
      end

      def self.nfs?
        # HostLinux checks for nfsd which returns false unless the
        # services are actively started. This leads to a misleading
        # error message. Checking for nfs (no d) seems to work
        # regardless. Also fixes useless use of cat, regex, and
        # redirection.
        Kernel.system("grep -Fq nfs /proc/filesystems")
      end

      # Normal, mid-range precedence.
      def self.precedence
        5
      end

      def initialize(*args)
        super
        if systemd?
          @nfs_check_command = "/usr/sbin/systemctl status nfsd"
          @nfs_start_command = "/usr/sbin/systemctl start nfsd rpc-idmapd rpc-mountd rpcbind"
        else
          @nfs_check_command = "/etc/rc.d/nfs-server status"
          @nfs_start_command = "sh -c 'for s in {rpcbind,nfs-common,nfs-server}; do /etc/rc.d/$s start; done'"
        end
      end

      protected

      # This tests to see if systemd is used on the system. This is used
      # in newer versions of Arch, and requires a change in behavior.
      def systemd?
        `ps -o comm= 1`.chomp == 'systemd'
      end
    end
  end
end
