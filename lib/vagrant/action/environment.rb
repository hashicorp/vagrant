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

      def initialize(env)
        @env = env
      end
    end
  end
end
