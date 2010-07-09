module Vagrant
  class Action
    # Represents an action environment which is what is passed
    # to the `call` method of each action. This environment contains
    # some helper methods for accessing the environment as well
    # as being a hash, to store any additional options.
    class Environment < Hash
      # The {Vagrant::Environment} object represented by this
      # action environment.
      attr_reader :env

      # If nonnil, the error associated with this environment. Set
      # using {#error!}
      attr_reader :error

      def initialize(env)
        super() do |h,k|
          # By default, try to find the key as a method on the
          # environment. Gross eval use here.
          begin
            value = eval("h.env.#{k}")
            h[k] = value
          rescue Exception
            nil
          end
        end

        @env = env
        @error = nil
      end

      # Returns a logger associated with the environment.
      def logger
        env.logger
      end

      # Flags the environment as erroneous. Stores the given key
      # and options until the end of the action sequence.
      #
      # @param [Symbol] key Key to translation to display error message.
      # @param [Hash] options Variables to pass to the translation
      def error!(key, options=nil)
        @error = [key, (options || {})]
      end

      # Returns boolean denoting if environment is in erroneous state.
      #
      # @return [Boolean]
      def error?
        !error.nil?
      end
    end
  end
end
