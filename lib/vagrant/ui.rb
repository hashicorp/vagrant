require "thread"

require "log4r"

require "vagrant/util/platform"
require "vagrant/util/safe_puts"

module Vagrant
  module UI
    # Vagrant UIs handle communication with the outside world (typically
    # through a shell). They must respond to the following methods:
    #
    # * `info`
    # * `warn`
    # * `error`
    # * `success`
    class Interface
      def initialize
        @logger   = Log4r::Logger.new("vagrant::ui::interface")
      end

      [:ask, :warn, :error, :info, :success].each do |method|
        define_method(method) do |message, *opts|
          # Log normal console messages
          @logger.info { "#{method}: #{message}" }
        end
      end

      [:clear_line, :report_progress].each do |method|
        # By default do nothing, these aren't logged
        define_method(method) { |*args| }
      end

      # Returns a new UI class that is scoped to the given resource name.
      # Subclasses can then use this scope name to do whatever they please.
      #
      # @param [String] scope_name
      # @return [Interface]
      def scope(scope_name)
        self
      end
    end

    # This is a UI implementation that does nothing.
    class Silent < Interface
      def ask(*args)
        super

        # Silent can't do this, obviously.
        raise Errors::UIExpectsTTY
      end
    end

    # This is a UI implementation that outputs the text as is. It
    # doesn't add any color.
    class Basic < Interface
      include Util::SafePuts

      def initialize
        super

        @lock = Mutex.new
      end

      # Use some light meta-programming to create the various methods to
      # output text to the UI. These all delegate the real functionality
      # to `say`.
      [:info, :warn, :error, :success].each do |method|
        class_eval <<-CODE
          def #{method}(message, *args)
            super(message)
            say(#{method.inspect}, message, *args)
          end
        CODE
      end

      def ask(message, opts=nil)
        super(message)

        # We can't ask questions when the output isn't a TTY.
        raise Errors::UIExpectsTTY if !$stdin.tty? && !Vagrant::Util::Platform.cygwin?

        # Setup the options so that the new line is suppressed
        opts ||= {}
        opts[:new_line] = false if !opts.has_key?(:new_line)
        opts[:prefix]   = false if !opts.has_key?(:prefix)

        # Output the data
        say(:info, message, opts)

        # Get the results and chomp off the newline. We do a logical OR
        # here because `gets` can return a nil, for example in the case
        # that ctrl-D is pressed on the input.
        input = $stdin.gets || ""
        input.chomp
      end

      # This is used to output progress reports to the UI.
      # Send this method progress/total and it will output it
      # to the UI. Send `clear_line` to clear the line to show
      # a continuous progress meter.
      def report_progress(progress, total, show_parts=true)
        if total && total > 0
          percent = (progress.to_f / total.to_f) * 100
          line    = "Progress: #{percent.to_i}%"
          line   << " (#{progress} / #{total})" if show_parts
        else
          line    = "Progress: #{progress}"
        end

        info(line, :new_line => false)
      end

      def clear_line
        reset = "\r"
        reset += "\e[0K" if Util::Platform.windows? && !Util::Platform.cygwin?

        info(reset, :new_line => false)
      end

      # This method handles actually outputting a message of a given type
      # to the console.
      def say(type, message, opts=nil)
        defaults = { :new_line => true, :prefix => true }
        opts     = defaults.merge(opts || {})

        # Determine whether we're expecting to output our
        # own new line or not.
        printer = opts[:new_line] ? :puts : :print

        # Determine the proper IO channel to send this message
        # to based on the type of the message
        channel = type == :error || opts[:channel] == :error ? $stderr : $stdout

        # Output! We wrap this in a lock so that it safely outputs only
        # one line at a time.
        @lock.synchronize do
          safe_puts(format_message(type, message, opts),
                    :io => channel, :printer => printer)
        end
      end

      def scope(scope_name)
        BasicScope.new(self, scope_name)
      end

      # This is called by `say` to format the message for output.
      def format_message(type, message, opts=nil)
        opts ||= {}
        message = "[#{opts[:scope]}] #{message}" if opts[:scope] && opts[:prefix]
        message
      end
    end

    # This implements a scope for the {Basic} UI.
    class BasicScope < Interface
      def initialize(ui, scope)
        super()

        @ui    = ui
        @scope = scope
      end

      [:ask, :warn, :error, :info, :success].each do |method|
        define_method(method) do |message, opts=nil|
          opts ||= {}
          opts[:scope] = @scope
          @ui.send(method, message, opts)
        end
      end

      [:clear_line, :report_progress].each do |method|
        # By default do nothing, these aren't logged
        define_method(method) { |*args| @ui.send(method, *args) }
      end
    end

    # This is a UI implementation that outputs color for various types
    # of messages. This should only be used with a TTY that supports color,
    # but is up to the user of the class to verify this is the case.
    class Colored < Basic
      # Terminal colors
      COLORS = {
        :clear  => "\e[0m",
        :red    => "\e[31m",
        :green  => "\e[32m",
        :yellow => "\e[33m"
      }

      # Mapping between type of message and the color to output
      COLOR_MAP = {
        :warn    => COLORS[:yellow],
        :error   => COLORS[:red],
        :success => COLORS[:green]
      }

      # This is called by `say` to format the message for output.
      def format_message(type, message, opts=nil)
        # Get the format of the message before adding color.
        message = super

        # Colorize the message if there is a color for this type of message,
        # either specified by the options or via the default color map.
        if opts.has_key?(:color)
          color   = COLORS[opts[:color]]
          message = "#{color}#{message}#{COLORS[:clear]}"
        else
          message = "#{COLOR_MAP[type]}#{message}#{COLORS[:clear]}" if COLOR_MAP[type]
        end

        message
      end
    end
  end
end
