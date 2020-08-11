module Vagrant
  module Util
    class TypedHash < Hash

      # Types available in the Hash
      attr_accessor :types

      def initialize(**opts)
        if opts[:types]
          @types = opts[:types]
        end
      end
    end
  end
end
