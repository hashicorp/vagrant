require 'vagrant/util/platform'

module Vagrant
  module Hosts
    class Windows < Base
      def self.match?
        Util::Platform.windows?
      end

      # Windows does not support NFS
      def nfs?
        false
      end
    end
  end
end
