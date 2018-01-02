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

      # @return [Boolean] powershell executable available on PATH
      def self.available?
        if !defined?(@_powershell_available)
          @_powershell_available = !!Which.which("powershell")
        end
        @_powershell_available
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
            "powershell",
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
          "powershell",
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

      # Returns the version of PowerShell that is installed.
      #
      # @return [String]
      def self.version
        if !defined?(@_powershell_version)
          command = [
            "powershell",
            "-NoLogo",
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy", "Bypass",
            "-Command",
            "Write-Output $PSVersionTable.PSVersion.Major"
          ].flatten

          r = Subprocess.execute(*command)
          @_powershell_version = r.exit_code != 0 ? nil : r.stdout.chomp
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
    end
  end
end
