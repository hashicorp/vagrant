require 'mario'

module Vagrant
  # Vagrant UIs handle communication with the outside world (typically
  # through a shell). They must respond to the typically logger methods
  # of `warn`, `error`, `info`, and `confirm`.
  class UI
    attr_accessor :env

    def initialize(env)
      @env = env
    end

    [:warn, :error, :info, :confirm, :say_with_vm, :report_progress, :ask, :no?, :yes?].each do |method|
      # By default these methods don't do anything. A silent UI.
      define_method(method) { |*args| }
    end

    # A shell UI, which uses a `Thor::Shell` object to talk with
    # a terminal.
    class Shell < UI
      def initialize(env, shell)
        super(env)

        @shell = shell
      end

      [[:warn, :yellow], [:error, :red], [:info, nil], [:confirm, :green]].each do |method, color|
        define_method(method) do |message, opts=nil|
          @shell.say("#{line_reset}#{format_message(message, opts)}", color)
        end
      end

      [:ask, :no?, :yes?].each do |method|
        define_method(method) do |message, opts=nil|
          opts ||= {}
          @shell.send(method, format_message(message, opts), opts[:_color])
        end
      end

      def report_progress(progress, total, show_parts=true)
        percent = (progress.to_f / total.to_f) * 100
        line = "Progress: #{percent.to_i}%"
        line << " (#{progress} / #{total})" if show_parts
        line = "#{line_reset}#{line}"

        @shell.say(line, nil, false)
      end

      protected

      def format_message(message, opts=nil)
        opts = { :_prefix => true, :_translate => true }.merge(opts || {})
        message = I18n.t(message, opts) if opts[:_translate]
        message = "[#{env.resource}] #{message}" if opts[:_prefix]
        message
      end

      def line_reset
        reset = "\r"
        reset += "\e[0K" unless Mario::Platform.windows?
        reset
      end
    end
  end
end
