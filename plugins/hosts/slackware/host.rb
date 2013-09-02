require "vagrant"

require Vagrant.source_root.join("plugins/hosts/linux/host")

module VagrantPlugins
  module HostSlackware
    class Host < VagrantPlugins::HostLinux::Host
      def self.match?
        return File.exists?("/etc/slackware-release") || Dir.glob("/usr/lib/setup/Plamo-*").length > 0
      end

      # Normal, mid-range precedence.
      def self.precedence
        5
      end

      def initialize(*args)
        super

        @nfs_apply_command = "/usr/sbin/exportfs -r"
        @nfs_check_command = "pidof nfsd > /dev/null"
        @nfs_start_command = "/etc/rc.d/rc.nfsd start"
      end
    end
  end
end
