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

        @nfs_server_binary = "/etc/init.d/nfs"
      end
    end
  end
end
