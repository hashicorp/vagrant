require 'vagrant/util/platform'

module Vagrant
  module Hosts
    # Represents a FreeBSD host
    class FreeBSD < BSD
      include Util
      include Util::Retryable

      def self.match?
        Util::Platform.freebsd?
      end

      def initialize(*args)
        super

        @nfs_restart_command = "sudo /etc/rc.d/mountd onereload"
      end
    end
  end
end
