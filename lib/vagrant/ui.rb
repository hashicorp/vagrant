require "log4r"

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
      attr_accessor :resource

      def initialize(resource)
        @logger   = Log4r::Logger.new("vagrant::ui::interface")
        @resource = resource
      end

      [:warn, :error, :info, :success].each do |method|
        define_method(method) do |message, *opts|
          # Log normal console messages
          @logger.info { "#{method}: #{message}" }
        end
      end

      [:clear_line, :report_progress].each do |method|
        # By default do nothing, these aren't logged
        define_method(method) { |*args| }
      end
    end

    # This is a UI implementation that does nothing.
    class Silent < Interface; end

    # This is a UI implementation that outputs the text as is. It
    # doesn't add any color.
    class Basic < Interface
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

      # This is used to output progress reports to the UI.
      # Send this method progress/total and it will output it
      # to the UI. Send `clear_line` to clear the line to show
      # a continuous progress meter.
      def report_progress(progress, total, show_parts=true)
        percent = (progress.to_f / total.to_f) * 100
        line    = "Progress: #{percent.to_i}%"
        line   << " (#{progress} / #{total})" if show_parts

        info(line, :new_line => false)
      end

      def clear_line
        reset = "\r"
        reset += "\e[0K" unless Util::Platform.windows?
        reset

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
        channel = type == :error ? $stderr : $stdout

        # Output!
        channel.send(printer, format_message(type, message, opts))
      end

      # This is called by `say` to format the message for output.
      def format_message(type, message, opts=nil)
        opts ||= {}
        message = "[#{@resource}] #{message}" if opts[:prefix]
        message
      end
    end

    # This is a UI implementation that outputs color for various types
    # of messages. This should only be used with a TTY that supports color,
    # but is up to the user of the class to verify this is the case.
    class Colored < Basic
      # Terminal colors
      CLEAR  = "\e[0m"
      YELLOW = "\e[33m"
      RED    = "\e[31m"
      GREEN  = "\e[32m"

      # Mapping between type of message and the color to output
      COLOR_MAP = {
        :warn    => YELLOW,
        :error   => RED,
        :success => GREEN
      }

      # This is called by `say` to format the message for output.
      def format_message(type, message, opts=nil)
        # Get the format of the message before adding color.
        message = super

        # Colorize the message if there is a color for this type of message
        message = "#{COLOR_MAP[type]}#{message}#{CLEAR}" if COLOR_MAP[type]
        message
      end
    end
  end
end
