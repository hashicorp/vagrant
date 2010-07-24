module Vagrant
  module Util
    # Subclass of the standard library logger which has no format on
    # its own. The message sent to the logger is outputted as-is.
    class PlainLogger < ::Logger
      # This is the method which is called for all debug, info, error,
      # etc. methods by the logger. This is overriden to verify that
      # the output is always flushed.
      #
      # Logger by default syncs all log devices but this just verifies
      # it is truly flushed.
      def add(*args)
        super
        @logdev.dev.flush if @logdev
      end

      def format_message(level, time, progname, msg)
        # We do no formatting, its up to the user
        "#{msg}\n"
      end
    end
  end
end
