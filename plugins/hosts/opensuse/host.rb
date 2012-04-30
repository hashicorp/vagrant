require "pathname"

module VagrantPlugins
  module HostOpenSUSE
    class Host < VagrantPlugins::HostLinux::Host
      def self.match?
        release_file = Pathname.new("/etc/SuSE-release")

        if release_file.exist?
          release_file.open("r") do |f|
            return true if f.gets =~ /^openSUSE/
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

        @nfs_server_binary = "/etc/init.d/nfsserver"
      end
    end
  end
end
