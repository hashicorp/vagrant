require "delegate"
require "io/console"
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
      # Opts can be used to set some options. These options are implementation
      # specific. See the implementation for more docs.
      attr_accessor :opts

      def initialize
        @logger   = Log4r::Logger.new("vagrant::ui::interface")
        @opts     = {}
      end

      [:ask, :detail, :warn, :error, :info, :output, :success].each do |method|
        define_method(method) do |message, *opts|
          # Log normal console messages
          @logger.info { "#{method}: #{message}" }
        end
      end

      [:clear_line, :report_progress].each do |method|
        # By default do nothing, these aren't logged
        define_method(method) { |*args| }
      end

      # For machine-readable output.
      #
      # @param [String] type The type of the data
      # @param [Array] data The data associated with the type
      def machine(type, *data)
        @logger.info("Machine: #{type} #{data.inspect}")
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

    class MachineReadable < Interface
      include Util::SafePuts

      def initialize
        super

        @lock = Mutex.new
      end

      def ask(*args)
        super

        # Machine-readable can't ask for input
        raise Errors::UIExpectsTTY
      end

      def machine(type, *data)
        opts = {}
        opts = data.pop if data.last.kind_of?(Hash)

        target = opts[:target] || ""

        # Prepare the data by replacing characters that aren't outputted
        data.each_index do |i|
          data[i] = data[i].to_s.dup
          data[i].gsub!(",", "%!(VAGRANT_COMMA)")
          data[i].gsub!("\n", "\\n")
          data[i].gsub!("\r", "\\r")
        end

        @lock.synchronize do
          safe_puts("#{Time.now.utc.to_i},#{target},#{type},#{data.join(",")}")
        end
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
      [:detail, :info, :warn, :error, :output, :success].each do |method|
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
        opts[:echo]     = true  if !opts.has_key?(:echo)
        opts[:new_line] = false if !opts.has_key?(:new_line)
        opts[:prefix]   = false if !opts.has_key?(:prefix)

        # Output the data
        say(:info, message, opts)

        input = nil
        if opts[:echo]
          input = $stdin.gets
        else
          input = $stdin.noecho(&:gets)

          # Output a newline because without echo, the newline isn't
          # echoed either.
          say(:info, "\n", opts)
        end

        # Get the results and chomp off the newline. We do a logical OR
        # here because `gets` can return a nil, for example in the case
        # that ctrl-D is pressed on the input.
        (input || "").chomp
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
        # See: http://en.wikipedia.org/wiki/ANSI_escape_code
        reset = "\r\033[K"

        info(reset, :new_line => false)
      end

      # This method handles actually outputting a message of a given type
      # to the console.
      def say(type, message, **opts)
        defaults = { :new_line => true, :prefix => true }
        opts     = defaults.merge(@opts).merge(opts)

        # Determine whether we're expecting to output our
        # own new line or not.
        printer = opts[:new_line] ? :puts : :print

        # Determine the proper IO channel to send this message
        # to based on the type of the message
        channel = type == :error || opts[:channel] == :error ? $stderr : $stdout

        # Output! We wrap this in a lock so that it safely outputs only
        # one line at a time. We wrap this in a thread because as of Ruby 2.0
        # we can't acquire locks in a trap context (ctrl-c), so we have to
        # do this.
        Thread.new do
          @lock.synchronize do
            safe_puts(format_message(type, message, **opts),
                      :io => channel, :printer => printer)
          end
        end.join
      end

      def format_message(type, message, **opts)
        message
      end
    end

    # Prefixed wraps an existing UI and adds a prefix to it.
    class Prefixed < Interface
      # The prefix for `output` messages.
      OUTPUT_PREFIX = "==> "

      def initialize(ui, prefix)
        super()

        @prefix = prefix
        @ui     = ui
      end

      # Use some light meta-programming to create the various methods to
      # output text to the UI. These all delegate the real functionality
      # to `say`.
      [:ask, :detail, :info, :warn, :error, :output, :success].each do |method|
        class_eval <<-CODE
          def #{method}(message, *args, **opts)
            super(message)
            if !opts.has_key?(:bold)
              opts[:bold] = #{method.inspect} != :detail && \
                #{method.inspect} != :ask
            end
            @ui.#{method}(format_message(#{method.inspect}, message, **opts), *args, **opts)
          end
        CODE
      end

      [:clear_line, :report_progress].each do |method|
        # By default do nothing, these aren't formatted
        define_method(method) { |*args| @ui.send(method, *args) }
      end

      # For machine-readable output, set the prefix in the
      # options hash and continue it on.
      def machine(type, *data)
        opts = {}
        opts = data.pop if data.last.is_a?(Hash)
        opts[:target] = @prefix
        data << opts
        @ui.machine(type, *data)
      end

      # Return the parent's opts.
      #
      # @return [Hash]
      def opts
        @ui.opts
      end

      def format_message(type, message, **opts)
        prefix = ""
        if !opts.has_key?(:prefix) || opts[:prefix]
          prefix = OUTPUT_PREFIX
          prefix = " " * OUTPUT_PREFIX.length if \
            type == :detail || type == :ask
        end

        # Fast-path if there is no prefix
        return message if prefix.empty?

        # Otherwise, make sure to prefix every line properly
        message.split("\n").map do |line|
          "#{prefix}#{@prefix}: #{line}"
        end.join("\n")
      end
    end

    # This is a UI implementation that outputs color for various types
    # of messages. This should only be used with a TTY that supports color,
    # but is up to the user of the class to verify this is the case.
    class Colored < Basic
      # Terminal colors
      COLORS = {
        red:     31,
        green:   32,
        yellow:  33,
        blue:    34,
        magenta: 35,
        cyan:    36,
        white:   37,
      }

      # This is called by `say` to format the message for output.
      def format_message(type, message, **opts)
        # Get the format of the message before adding color.
        message = super

        opts = @opts.merge(opts)

        # Special case some colors for certain message types
        opts[:color] = :red if type == :error
        opts[:color] = :green if type == :success
        opts[:color] = :yellow if type == :warn

        # If it is a detail, it is not bold. Every other message type
        # is bolded.
        bold  = !!opts[:bold]
        colorseq = "#{bold ? 1 : 0 }"
        if opts[:color]
          color = COLORS[opts[:color]]
          colorseq += ";#{color}"
        end

        # Color the message and make sure to reset the color at the end
        "\033[#{colorseq}m#{message}\033[0m"
      end
    end
  end
end
