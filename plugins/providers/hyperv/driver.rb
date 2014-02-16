require "json"

require "vagrant/util/powershell"

require_relative "plugin"

module VagrantPlugins
  module HyperV
    class Driver
      ERROR_REGEXP  = /===Begin-Error===(.+?)===End-Error===/m
      OUTPUT_REGEXP = /===Begin-Output===(.+?)===End-Output===/m

      attr_reader :vmid

      def initialize(id=nil)
        @vmid = id
        @output = nil
      end

      def execute(path, options)
        r = execute_powershell(path, options)
        if r.exit_code != 0
          raise Errors::PowerShellError,
            script: path,
            stderr: r.stderr
        end

        # We only want unix-style line endings within Vagrant
        r.stdout.gsub!("\r\n", "\n")
        r.stderr.gsub!("\r\n", "\n")

        error_match  = ERROR_REGEXP.match(r.stdout)
        output_match = OUTPUT_REGEXP.match(r.stdout)

        if error_match
          data = JSON.parse(error_match[1])

          # We have some error data.
          raise Errors::PowerShellError,
            script: path,
            stderr: data["error"]
        end

        # Nothing
        return nil if !output_match
        return JSON.parse(output_match[1])
      end

      protected

      def json_output
        return @json_output if @json_output
        json_success_begin = false
        json_error_begin = false
        success = []
        error = []
        @output.split("\n").each do |line|
          json_error_begin = false if line.include?("===End-Error===")
          json_success_begin = false if line.include?("===End-Output===")
          message = ""
          if json_error_begin || json_success_begin
            message = line.gsub("\\'","\"")
          end
          success << message if json_success_begin
          error << message if json_error_begin
          json_success_begin = true if line.include?("===Begin-Output===")
          json_error_begin = true if line.include?("===Begin-Error===")
        end
        @json_output = { :success => success, :error => error }
      end

      def success?
        @error_messages.empty? && json_output[:error].empty?
      end

      def process_output(type, data)
        if type == :stdout
          @output = data.gsub("\r\n", "\n")
        end
        if type == :stdin
          # $stdin.gets.chomp || ""
        end
        if type == :stderr
          @error_messages = data.gsub("\r\n", "\n")
        end
      end

      def clear_output_buffer
        @output = ""
        @error_messages = ""
        @json_output = nil
      end

      def execute_powershell(path, options, &block)
        lib_path = Pathname.new(File.expand_path("../scripts", __FILE__))
        path = lib_path.join(path).to_s.gsub("/", "\\")
        options = options || {}
        ps_options = []
        options.each do |key, value|
          ps_options << "-#{key}"
          ps_options << "'#{value}'"
        end
        clear_output_buffer
        opts = { notify: [:stdout, :stderr, :stdin] }
        Vagrant::Util::PowerShell.execute(path, *ps_options, **opts, &block)
      end
    end
  end
end
