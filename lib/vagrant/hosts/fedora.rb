require 'pathname'

module Vagrant
  module Hosts
    class Fedora < Linux
      def self.match?
        release_file = Pathname.new("/etc/redhat-release")

        if release_file.exist?
          release_file.open("r") do |f|
            return true if f.gets =~ /^Fedora/
          end
        end

        false
      end

      # Normal, mid-range precedence.
      def self.precedence
        5
      end

      def initialize(*args)
        super

        @nfs_server_binary = "/etc/init.d/nfs"

        # On Fedora 16+, systemd replaced init.d, so we have to use the
        # proper NFS binary. This checks to see if we need to do that.
        release_file = Pathname.new("/etc/redhat-release")
        begin
          release_file.open("r") do |f|
            version_number = /Fedora release ([0-9]+)/.match(f.gets)[1].to_i
            if version_number >= 16
              # "service nfs-server" will redirect properly to systemctl
              # when "service nfs-server restart" is called.
              @nfs_server_binary = "/usr/sbin/service nfs-server"
            end
          end
        rescue Errno::ENOENT
          # File doesn't exist, not a big deal, assume we're on a
          # lower version.
        end
      end
    end
  end
end
