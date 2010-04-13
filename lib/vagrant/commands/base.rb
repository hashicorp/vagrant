module Vagrant
  class Commands
    # This is the base command class which all sub-commands must
    # inherit from.
    class Base
      attr_reader :env

      def initialize(env)
        @env = env
      end

      def execute(args)

      end
    end
  end
end