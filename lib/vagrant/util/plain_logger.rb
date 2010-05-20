module Vagrant
  module Util
    # Subclass of the standard library logger which has no format on
    # its own. The message sent to the logger is outputted as-is.
    class PlainLogger < ::Logger
      def format_message(level, time, progname, msg)
        # We do no formatting, its up to the user
        "#{msg}\n"
      end
    end
  end
end
