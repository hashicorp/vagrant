module VagrantPlugins
  module CommunicatorWinRM
    module CommandFilters

      # Converts a *nix 'chmod' command to a PowerShell equivalent
      class Chmod

        def filter(command)
          # Not support on Windows, the communicator will skip this command
          ''
        end

        def accept?(command)
          command.start_with?('chmod ')
        end

      end

    end
  end
end
