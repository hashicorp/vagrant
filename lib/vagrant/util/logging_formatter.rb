require "vagrant/util/credential_scrubber"
require "log4r/formatter/formatter"

module Vagrant
  module Util
    # Wrapper for logging formatting to provide
    # information scrubbing prior to being written
    # to output target
    class LoggingFormatter < Log4r::BasicFormatter

      # @return [Log4r::PatternFormatter]
      attr_reader :formatter

      # Creates a new formatter wrapper instance.
      #
      # @param [Log4r::Formatter]
      def initialize(formatter)
        @formatter = formatter
      end

      # Format event and scrub output
      def format(event)
        msg = formatter.format(event)
        CredentialScrubber.desensitize(msg)
      end
    end
  end
end
