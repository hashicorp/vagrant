module Vagrant
  class Action
    # Represents an action environment which is what is passed
    # to the `call` method of each action. This environment contains
    # some helper methods for accessing the environment as well
    # as being a hash, to store any additional options.
    class Environment < Util::HashWithIndifferentAccess
      # The {Vagrant::Environment} object represented by this
      # action environment.
      attr_reader :env

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
        @interrupted = false
      end

      # Returns a UI object from the environment
      def ui
        env.ui
      end

      # Marks an environment as interrupted (by an outside signal or
      # anything)
      def interrupt!
        @interrupted = true
      end

      # Returns a boolean denoting if environment has been interrupted
      # with a SIGINT.
      def interrupted?
        !!@interrupted
      end
    end
  end
end
