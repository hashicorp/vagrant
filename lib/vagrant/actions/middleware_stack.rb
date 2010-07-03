module Vagrant
  module Actions
    # Represents a middleware stack for Vagrant actions. Vagrant
    # actions are created and can be extended with middlewares.
    #
    # The exact nature of how this will work is not set in stone.
    class MiddlewareStack
      # Initializes the middleware stack with the given name.
      def initialize(key)
        @stack = []
      end

      def use(klass)
        @stack << klass
      end

      def run(endpoint)
        @stack << endpoint
      end
    end
  end
end
