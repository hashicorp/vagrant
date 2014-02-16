require "json"

require "vagrant/util/powershell"

require_relative "plugin"

module VagrantPlugins
  module HyperV
    class Driver
      attr_reader :vmid

      def initialize(id=nil)
        @vmid = id
        @output = nil
      end

      def execute(path, options)
        r = execute_powershell(path, options) do |type, data|
          process_output(type, data)
        end
        if r.exit_code != 0
          raise Errors::PowerShellError,
            script: path,
            stderr: r.stderr
        end

        if success?
          JSON.parse(json_output[:success].join) unless json_output[:success].empty?
        else
          message = json_output[:error].join unless json_output[:error].empty?
          raise Error::SubprocessError, message if message
        end
      end

      def raw_execute(command)
        command = [command , {notify: [:stdout, :stderr, :stdin]}].flatten
        clear_output_buffer
        Vagrant::Util::Subprocess.execute(*command) do |type, data|
          process_output(type, data)
        end
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
        lib_path = Pathname.new(File.expand_path("../../scripts", __FILE__))
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
