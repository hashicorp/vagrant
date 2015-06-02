module VagrantPlugins
  module CommunicatorWinRM
    module CommandFilters
      # Converts a *nix 'mkdir' command to a PowerShell equivalent
      class Mkdir
        def filter(command)
          # mkdir -p /some/dir
          # mkdir /some/dir
          cmd_parts = command.strip.split(/\s+/)
          dir = cmd_parts.pop
          while !dir.nil? && dir.start_with?('-')
            dir = cmd_parts.pop
          end
          # This will ignore any -p switches, which are redundant in PowerShell,
          # and ambiguous in PowerShell 4+
          return "mkdir #{dir} -force"
        end

        def accept?(command)
          command.start_with?('mkdir ')
        end
      end
    end
  end
end
