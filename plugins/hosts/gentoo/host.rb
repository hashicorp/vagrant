require "vagrant"

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
        @nfs_check_command = "service nfs status"
        @nfs_start_command = "service nfs start"
      end
    end
  end
end
