module VagrantPlugins
  module CommunicatorWinRM
    module CommandFilters
      # Converts a *nix 'which' command to a PowerShell equivalent
      class Which
        def filter(command)
          executable = command.strip.split(/\s+/)[1]
          return <<-EOH
            $command = [Array](Get-Command #{executable} -errorAction SilentlyContinue)
            if ($null -eq $command) { exit 1 }
            write-host $command[0].Definition
            exit 0
          EOH
        end

        def accept?(command)
          command.start_with?('which ')
        end
      end
    end
  end
end
