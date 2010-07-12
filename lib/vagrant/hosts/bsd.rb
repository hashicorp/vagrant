module Vagrant
  module Hosts
    # Represents a BSD host, such as FreeBSD and Darwin (Mac OS X).
    class BSD < Base
      def nfs?
        # TODO: verify it exists
        true
      end
    end
  end
end
