require "tmpdir"
require_relative "subprocess"
require_relative "which"

module Vagrant
  module Util
    # Executes PowerShell scripts.
    #
    # This is primarily a convenience wrapper around Subprocess that
    # properly sets powershell flags for you.
    class PowerShell
      # NOTE: Version checks are only on Major
      MINIMUM_REQUIRED_VERSION = 3
      # Number of seconds to wait while attempting to get powershell version
      DEFAULT_VERSION_DETECTION_TIMEOUT = 30
      LOGGER = Log4r::Logger.new("vagrant::util::powershell")

      # @return [String|nil] a powershell executable, depending on environment
      def self.executable
        if !defined?(@_powershell_executable)
          @_powershell_executable = "powershell"

          # Try to use WSL interoperability if PowerShell is not symlinked to
          # the container.
          if Which.which(@_powershell_executable).nil? && Platform.wsl?
            @_powershell_executable += ".exe"

            if Which.which(@_powershell_executable).nil?
              @_powershell_executable = nil
            end
          end
        end
        @_powershell_executable
      end

      # @return [Boolean] powershell executable available on PATH
      def self.available?
        !executable.nil?
      end

      # Execute a powershell script.
      #
      # @param [String] path Path to the PowerShell script to execute.
      # @return [Subprocess::Result]
      def self.execute(path, *args, **opts, &block)
        validate_install!
        if opts.delete(:sudo) || opts.delete(:runas)
          powerup_command(path, args, opts)
        else
          command = [
            executable,
            "-NoLogo",
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy", "Bypass",
            "&('#{path}')",
            args
          ].flatten

          # Append on the options hash since Subprocess doesn't use
          # Ruby 2.0 style options yet.
          command << opts

          Subprocess.execute(*command, &block)
        end
      end

      # Execute a powershell command.
      #
      # @param [String] command PowerShell command to execute.
      # @return [nil, String] Returns nil if exit code is non-zero.
      #   Returns stdout string if exit code is zero.
      def self.execute_cmd(command)
        validate_install!
        c = [
          executable,
          "-NoLogo",
          "-NoProfile",
          "-NonInteractive",
          "-ExecutionPolicy", "Bypass",
          "-Command",
          command
        ].flatten.compact

        r = Subprocess.execute(*c)
        return nil if r.exit_code != 0
        return r.stdout.chomp
      end

      # Execute a powershell command and return a result
      #
      # @param [String] command PowerShell command to execute.
      # @param [Hash] opts A collection of options for subprocess::execute
      # @param [Block] block Ruby block
      def self.execute_inline(*command, **opts, &block)
        validate_install!
        c = [
          executable,
          "-NoLogo",
          "-NoProfile",
          "-NonInteractive",
          "-ExecutionPolicy", "Bypass",
          "-Command",
          command
        ].flatten.compact
        c << opts

        Subprocess.execute(*c, &block)
      end

      # Returns the version of PowerShell that is installed.
      #
      # @return [String]
      def self.version
        if !defined?(@_powershell_version)
          command = [
            executable,
            "-NoLogo",
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy", "Bypass",
            "-Command",
            "Write-Output $PSVersionTable.PSVersion.Major"
          ].flatten

          version = nil
          timeout = ENV["VAGRANT_POWERSHELL_VERSION_DETECTION_TIMEOUT"].to_i
          if timeout < 1
            timeout = DEFAULT_VERSION_DETECTION_TIMEOUT
          end
          begin
            r = Subprocess.execute(*command,
              notify: [:stdout, :stderr],
              timeout: timeout,
            ) {|io_name,data| version = data}
          rescue Vagrant::Util::Subprocess::TimeoutExceeded
            LOGGER.debug("Timeout exceeded while attempting to determine version of Powershell.")
          end

          @_powershell_version = version
        end
        @_powershell_version
      end

      # Validates that powershell is installed, available, and
      # at or above minimum required version
      #
      # @return [Boolean]
      # @raises []
      def self.validate_install!
        if !defined?(@_powershell_validation)
          raise Errors::PowerShellNotFound if !available?
          if version.to_i < MINIMUM_REQUIRED_VERSION
            raise Errors::PowerShellInvalidVersion,
              minimum_version: MINIMUM_REQUIRED_VERSION,
              installed_version: version ? version : "N/A"
          end
          @_powershell_validation = true
        end
        @_powershell_validation
      end

      # Powerup the given command to perform privileged operations.
      #
      # @param [String] path
      # @param [Array<String>] args
      # @return [Array<String>]
      def self.powerup_command(path, args, opts)
        Dir.mktmpdir("vagrant") do |dpath|
          all_args = ["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", path] + args
          arg_list = "@('" + all_args.join("', '") + "')"
          stdout = File.join(dpath, "stdout.txt")
          stderr = File.join(dpath, "stderr.txt")
          exitcode = File.join(dpath, "exitcode.txt")

          script = "$sp = Start-Process -FilePath powershell -ArgumentList #{arg_list} " \
            "-PassThru -Wait -RedirectStandardOutput '#{stdout}' -RedirectStandardError '#{stderr}' -WindowStyle Hidden; " \
            "if($sp){ Set-Content -Path '#{exitcode}' -Value $sp.ExitCode;exit $sp.ExitCode; }else{ exit 1 }"

          # escape quotes so we can nest our script within a start-process
          script.gsub!("'", "''")

          cmd = [
            "powershell",
            "-NoLogo",
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy", "Bypass",
            "-Command", "$p = Start-Process -FilePath powershell -ArgumentList " \
              "@('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-Command', '#{script}') " \
              "-PassThru -Wait -WindowStyle Hidden -Verb RunAs; if($p){ exit $p.ExitCode; }else{ exit 1 }"
          ]

          result = Subprocess.execute(*cmd.push(opts))
          if File.exist?(stdout)
            r_stdout = File.read(stdout)
          else
            r_stdout = result.stdout
          end
          if File.exist?(stderr)
            r_stderr = File.read(stderr)
          else
            r_stderr = result.stderr
          end

          code = 1
          if File.exist?(exitcode)
            code_txt = File.read(exitcode).strip
            if code_txt.match(/^\d+$/)
              code = code_txt.to_i
            end
          end
          Subprocess::Result.new(code, r_stdout, r_stderr)
        end
      end

      # @private
      # Reset the cached values for platform. This is not considered a public
      # API and should only be used for testing.
      def self.reset!
        instance_variables.each(&method(:remove_instance_variable))
      end
    end
  end
end
