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

        release_file = Pathname.new("/etc/redhat-release")

        @nfs_server_binary = "/etc/init.d/nfs"

        if release_file.exist?
          release_file.open("r") do |f|
            version_number = /Fedora release ([0-9]+)/.match(f.gets)[1].to_i
            if version_number >= 17
              # For now, "service nfs-server" will redirect properly to systemctl
              # when "service nfs-server restart" is called.
              @nfs_server_binary = "/usr/sbin/service nfs-server"
            end
          end
        end

      end
    end
  end
end
