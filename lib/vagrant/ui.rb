require 'mario'

module Vagrant
  # Vagrant UIs handle communication with the outside world (typically
  # through a shell). They must respond to the typically logger methods
  # of `warn`, `error`, `info`, and `confirm`.
  class UI
    attr_reader :env

    def initialize(env)
      @env = env
    end

    [:warn, :error, :info, :confirm, :say_with_vm, :report_progress].each do |method|
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
        define_method(method) do |message, prepend_vm_name=true|
          message = format_message(message) if prepend_vm_name
          @shell.say("#{line_reset}#{message}", color)
        end
      end

      def report_progress(progress, total, show_parts=true)
        percent = (progress.to_f / total.to_f) * 100
        line = "Progress: #{percent.to_i}%"
        line << " (#{data[:progress]} / #{data[:total]})" if data[:show_parts]
        line = "#{line_reset}#{line}"

        @shell.say(line, nil, false)
      end

      protected

      def format_message(message)
        name = env.vm_name || "vagrant"
        "[#{name}] #{message}"
      end

      def line_reset
        reset = "\r"
        reset += "\e[0K" unless Mario::Platform.windows?
        reset
      end
    end
  end
end
