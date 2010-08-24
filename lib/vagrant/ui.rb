module Vagrant
  # Vagrant UIs handle communication with the outside world (typically
  # through a shell). They must respond to the typically logger methods
  # of `warn`, `error`, `info`, and `confirm`.
  class UI
    [:warn, :error, :info, :confirm].each do |method|
      # By default these methods don't do anything. A silent UI.
      define_method(method) { |message| }
    end

    # A shell UI, which uses a `Thor::Shell` object to talk with
    # a terminal.
    class Shell < UI
      def initialize(shell)
        @shell = shell
      end

      def warn(message)
        @shell.say(message, :yellow)
      end

      def error(message)
        @shell.say(message, :red)
      end

      def info(message)
        @shell.say(message)
      end

      def confirm(message)
        @shell.say(message, :green)
      end
    end
  end
end
