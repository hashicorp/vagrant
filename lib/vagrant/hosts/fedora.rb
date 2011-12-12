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

      def initialize(*args)
        super

        @nfs_server_binary = "/etc/init.d/nfs"
      end
    end
  end
end
