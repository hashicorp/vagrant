# This file contains all the errors that the V1 plugin interface
# may throw.

module Vagrant
  module Plugin
    module V1
      # Exceptions that can be thrown within the plugin interface all
      # inherit from this parent exception.
      class Error < StandardError; end

      # This is thrown when a command name given is invalid.
      class InvalidCommandName < Error; end
    end
  end
end
