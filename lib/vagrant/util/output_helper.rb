module Vagrant
  module Util
    module OutputHelper
      def wrap_output
        puts "====================================================================="
        yield
        puts "====================================================================="
      end
    end
  end
end
