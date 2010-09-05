module Vagrant
  class Config
    # A class which is passed into the various {Base#validate} methods and
    # can be used as a helper to add error messages about a single config
    # class.
    class ErrorRecorder
      attr_reader :errors

      def initialize
        @errors = []
      end

      # Adds an error to the list of errors. The message key must be a key
      # to an I18n translatable error message. Opts can be specified as
      # interpolation variables for the message.
      def add(message_key, opts=nil)
        @errors << I18n.t(message_key, opts)
      end
    end
  end
end
