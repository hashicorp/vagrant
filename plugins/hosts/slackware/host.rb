require "vagrant"

require Vagrant.source_root.join("plugins/hosts/linux/host")

module VagrantPlugins
  module HostSlackware
    class Host < VagrantPlugins::HostLinux::Host
      def self.match?
        return File.exists?("/etc/slackware-release")
      end

      # Normal, mid-range precedence.
      def self.precedence
        5
      end

      def initialize(*args)
        super

        @nfs_apply_command = "/usr/sbin/exportfs -r"
        @nfs_check_command = "/etc/rc.d/rc.nfsd status"
        @nfs_start_command = "/etc/rc.d/rc.nfsd start"
      end
    end
  end
end
