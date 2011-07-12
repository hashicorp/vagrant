require 'thread'

module Vagrant
  module Util
    # Atomic counter implementation. This is useful for incrementing
    # a counter which is guaranteed to only be used once in its class.
    module Counter
      def get_and_update_counter
        mutex.synchronize do
          @__counter ||= 1
          result = @__counter
          @__counter += 1
          result
        end
      end

      def mutex
        @__counter_mutex ||= Mutex.new
      end
    end
  end
end
