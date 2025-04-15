# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "base64"
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
      # Names of the powershell executable
      POWERSHELL_NAMES = ["pwsh", "powershell"].map(&:freeze).freeze
      # Paths to powershell executable
      POWERSHELL_PATHS = [
        "%SYSTEMROOT%/System32/WindowsPowerShell/v1.0",
        "%WINDIR%/System32/WindowsPowerShell/v1.0",
        "%PROGRAMFILES%/PowerShell/7",
        "%PROGRAMFILES%/PowerShell/6"
      ].map(&:freeze).freeze

      LOGGER = Log4r::Logger.new("vagrant::util::powershell")

      # @return [String|nil] a powershell executable, depending on environment
      def self.executable
        if !defined?(@_powershell_executable)
          prefer_name = ENV["VAGRANT_PREFERRED_POWERSHELL"].to_s.sub(".exe", "")
          if !POWERSHELL_NAMES.include?(prefer_name)
            prefer_name = POWERSHELL_NAMES.first
          end

          LOGGER.debug("preferred powershell executable name: #{prefer_name}")

          # First start with detecting executable on configured path
          found_shells = Hash.new.tap do |found|
            POWERSHELL_NAMES.each do |psh|
              psh_path = Which.which(psh)
              psh_path = Which.which(psh + ".exe") if !psh_path
              next if !psh_path

              LOGGER.debug("detected powershell for #{psh.inspect} - #{psh_path}")
              found[psh] = psh_path
            end
          end

          # Done if preferred shell was found
          if found_shells.key?(prefer_name)
            LOGGER.debug("using preferred powershell #{prefer_name.inspect} - #{found_shells[prefer_name]}")
            return @_powershell_executable = found_shells[prefer_name]
          end

          # Now attempt with paths
          paths = POWERSHELL_PATHS.map do |ppath|
            result = Util::Subprocess.execute("cmd.exe", "/c", "echo #{ppath}")
            result.stdout.gsub("\"", "").strip if result.exit_code == 0
          end.compact

          paths.each do |psh_path|
            POWERSHELL_NAMES.each do |psh|
              next if found_shells.key?(psh)

              path = File.join(psh_path, psh)
              [path, "#{path}.exe", path.sub(/^([A-Za-z]):/, "/mnt/\\1")].each do |full_path|
                if File.executable?(full_path)
                  found_shells[psh] = full_path
                  break
                end
              end
            end
          end

          # Done if preferred shell was found
          if found_shells.key?(prefer_name)
            LOGGER.debug("using preferred powershell #{prefer_name.inspect} - #{found_shells[prefer_name]}")
            return @_powershell_executable = found_shells[prefer_name]
          end

          # Iterate names and return first found
          POWERSHELL_NAMES.each do |psh|
            LOGGER.debug("using powershell #{prefer_name.inspect} - #{found_shells[prefer_name]}")
            return @_powershell_executable = found_shells[psh] if found_shells.key?(psh)
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
      # @param [Array<String>] args Command arguments
      # @param [Hash] opts Options passed to execute
      # @option opts [Hash] :env Custom environment variables
      # @return [Subprocess::Result]
      def self.execute(path, *args, **opts, &block)
        validate_install!
        if opts.delete(:sudo) || opts.delete(:runas)
          powerup_command(path, args, opts)
        else
          if mpath = opts.delete(:module_path)
            m_env = opts.fetch(:env, {})
            m_env["PSModulePath"] = "$env:PSModulePath+';#{mpath}'"
            opts[:env] = m_env
          end
          if env = opts.delete(:env)
            env = env.map{|k,v| "$env:#{k}=#{v}"}.join(";") + "; "
          end
          command = [
            executable,
            "-NoLogo",
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy", "Bypass",
            "-Command",
            "#{env}&('#{path}')",
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
      # @param [Hash] opts Extra options
      # @option opts [Hash] :env Custom environment variables
      # @return [nil, String] Returns nil if exit code is non-zero.
      #   Returns stdout string if exit code is zero.
      def self.execute_cmd(command, **opts)
        validate_install!
        if mpath = opts.delete(:module_path)
          m_env = opts.fetch(:env, {})
          m_env["PSModulePath"] = "$env:PSModulePath+';#{mpath}'"
          opts[:env] = m_env
        end
        if env = opts.delete(:env)
          env = env.map{|k,v| "$env:#{k}=#{v}"}.join(";") + "; "
        end
        c = [
          executable,
          "-NoLogo",
          "-NoProfile",
          "-NonInteractive",
          "-ExecutionPolicy", "Bypass",
          "-Command",
          "#{env}#{command}"
        ].flatten.compact

        r = Subprocess.execute(*c)
        return nil if r.exit_code != 0
        return r.stdout.chomp
      end

      # Execute a powershell command and return a result
      #
      # @param [String] command PowerShell command to execute.
      # @param [Hash] opts A collection of options for subprocess::execute
      # @option opts [Hash] :env Custom environment variables
      # @param [Block] block Ruby block
      def self.execute_inline(*command, **opts, &block)
        validate_install!
        if mpath = opts.delete(:module_path)
          m_env = opts.fetch(:env, {})
          m_env["PSModulePath"] = "$env:PSModulePath+';#{mpath}'"
          opts[:env] = m_env
        end
        if env = opts.delete(:env)
          env = env.map{|k,v| "$env:#{k}=#{v}"}.join(";") + "; "
        end

        command = command.join(' ')

        c = [
          executable,
          "-NoLogo",
          "-NoProfile",
          "-NonInteractive",
          "-ExecutionPolicy", "Bypass",
          "-Command",
          "#{env}#{command}"
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
          all_args = [path] + args.flatten.map{ |a|
            a.gsub(/^['"](.+)['"]$/, "\\1")
          }
          arg_list = "\"" + all_args.join("\" \"") + "\""
          stdout = File.join(dpath, "stdout.txt")
          stderr = File.join(dpath, "stderr.txt")

          script = "& #{arg_list} ; exit $LASTEXITCODE;"
          script_content = Base64.strict_encode64(script.encode("UTF-16LE", "UTF-8"))

          # Wrap so we can redirect output to read later
          wrapper = "$p = Start-Process -FilePath powershell -ArgumentList @('-NoLogo', '-NoProfile', " \
            "'-NonInteractive', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', '#{script_content}') " \
            "-PassThru -WindowStyle Hidden -Wait -RedirectStandardOutput '#{stdout}' -RedirectStandardError '#{stderr}'; " \
            "if($p){ exit $p.ExitCode; }else{ exit 1 }"
          wrapper_content = Base64.strict_encode64(wrapper.encode("UTF-16LE", "UTF-8"))

          powerup = "$p = Start-Process -FilePath powershell -ArgumentList @('-NoLogo', '-NoProfile', " \
            "'-NonInteractive', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', '#{wrapper_content}') " \
            "-PassThru -WindowStyle Hidden -Wait -Verb RunAs; if($p){ exit $p.ExitCode; }else{ exit 1 }"

          cmd = [
            executable,
            "-NoLogo",
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy", "Bypass",
            "-Command", powerup
          ]

          result = Subprocess.execute(*cmd.push(opts))
          r_stdout = result.stdout
          if File.exist?(stdout)
            r_stdout += File.read(stdout)
          end
          r_stderr = result.stderr
          if File.exist?(stderr)
            r_stderr += File.read(stderr)
          end

          Subprocess::Result.new(result.exit_code, r_stdout, r_stderr)
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
