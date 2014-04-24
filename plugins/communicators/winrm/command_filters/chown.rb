module VagrantPlugins
  module CommunicatorWinRM
    module CommandFilters
      # Converts a *nix 'chown' command to a PowerShell equivalent (none)
      class Chown
        def filter(command)
          # Not supported on Windows, the communicator should skip this command
          ''
        end

        def accept?(command)
          command.start_with?('chown ')
        end
      end
    end
  end
end
