module Vagrant
  module Exceptions
    # Raised when an action sequence is trying to be run for an uncallable
    # action (not a lambda, middleware, or registered sequence).
    class UncallableAction < ::Exception
      def initialize(callable)
        super()

        @callable = callable
      end

      def to_s
        @callable.inspect
      end
    end
  end
end
