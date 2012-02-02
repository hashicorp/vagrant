require 'pathname'

module Vagrant
  module Hosts
    class Gentoo < Linux
      def self.match?
        release_file = Pathname.new("/etc/gentoo-release")

        return release_file.exist?
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
