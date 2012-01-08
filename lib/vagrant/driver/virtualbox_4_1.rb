module Vagrant
  module Driver
    # Driver to communicate with VirtualBox 4.1.x
    class VirtualBox_4_1
      def initialize(uuid)
        @uuid = uuid
      end
    end
  end
end
