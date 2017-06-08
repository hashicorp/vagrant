require_relative "subprocess"
require_relative "which"

module Vagrant
  module Util
    # Executes PowerShell scripts.
    #
    # This is primarily a convenience wrapper around Subprocess that
    # properly sets powershell flags for you.
    class PowerShell
      def self.available?
        !!Which.which("powershell")
      end

      # Execute a powershell script.
      #
      # @param [String] path Path to the PowerShell script to execute.
      # @return [Subprocess::Result]
      def self.execute(path, *args, **opts, &block)
        command = [
          "powershell",
          "-NoLogo",
          "-NoProfile",
          "-NonInteractive",
          "-ExecutionPolicy", "Bypass",
          "&('#{path}'); Stop-Process $pid",
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
        c = [
          "powershell",
          "-NoLogo",
          "-NoProfile",
          "-NonInteractive",
          "-ExecutionPolicy", "Bypass",
          "-Command",
          "#{command}; Stop-Process $pid",
        ].flatten

        r = Subprocess.execute(*c)
        return nil if r.exit_code != 0
        return r.stdout.chomp
      end

      # Returns the version of PowerShell that is installed.
      #
      # @return [String]
      def self.version
        command = [
          "powershell",
          "-NoLogo",
          "-NoProfile",
          "-NonInteractive",
          "-ExecutionPolicy", "Bypass",
          "-Command",
          "$PSVersionTable.PSVersion.Major; Stop-Process $pid",
        ].flatten

        r = Subprocess.execute(*command)
        return nil if r.exit_code != 0
        return r.stdout.chomp
      end
    end
  end
end
