module Vagrant
  module Config
    # A class which is passed into the various {Base#validate} methods and
    # can be used as a helper to add error messages about a single config
    # class.
    class ErrorRecorder
      attr_reader :errors

      def initialize
        @errors = []
      end

      # Adds an error to the list of errors.
      def add(message)
        @errors << message
      end
    end
  end
end
