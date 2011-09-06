module Vagrant
  module Hosts
    class Fedora < Linux
      def initialize(*args)
        super

        @nfs_server_binary = "/etc/init.d/nfs"
      end
    end
  end
end
