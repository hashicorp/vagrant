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

      # Execute a powershell command.
      #
      # @param [String] command PowerShell command to execute.
      # @return [Subprocess::Result]
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
            "powershell",
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
