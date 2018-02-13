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

      # Execute a powershell command.
      #
      # @param [String] command PowerShell command to execute.
      # @return [Subprocess::Result]
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
        ].flatten

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
            executable,
            "-NoLogo",
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy", "Bypass",
            "-Command",
            "$PSVersionTable.PSVersion.Major"
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
    end
  end
end
