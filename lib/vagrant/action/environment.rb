require 'vagrant/util/hash_with_indifferent_access'

module Vagrant
  module Action
    # Represents an action environment which is what is passed
    # to the `call` method of each action. This environment contains
    # some helper methods for accessing the environment as well
    # as being a hash, to store any additional options.
    class Environment < Util::HashWithIndifferentAccess
    end
  end
end
