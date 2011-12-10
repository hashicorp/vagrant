require 'vagrant/util/hash_with_indifferent_access'

module Vagrant
  module Action
    # Represents an action environment which is what is passed
    # to the `call` method of each action. This environment contains
    # some helper methods for accessing the environment as well
    # as being a hash, to store any additional options.
    class Environment < Util::HashWithIndifferentAccess
      def initialize
        @interrupted = false
      end

      # Marks an environment as interrupted (by an outside signal or
      # anything). This will trigger any middleware sequences using this
      # environment to halt. This is automatically set by {Action} when
      # a SIGINT is captured.
      def interrupt!
        @interrupted = true
      end

      # Returns a boolean denoting if environment has been interrupted
      # with a SIGINT.
      #
      # @return [Bool]
      def interrupted?
        !!@interrupted
      end
    end
  end
end
