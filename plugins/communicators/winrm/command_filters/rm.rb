module VagrantPlugins
  module CommunicatorWinRM
    module CommandFilters
      # Converts a *nix 'rm' command to a PowerShell equivalent
      class Rm
        def filter(command)
          # rm -Rf /some/dir
          # rm /some/dir
          cmd_parts = command.strip.split(/\s+/)
          dir = cmd_parts[1]
          if dir == '-Rf'
            dir = cmd_parts[2]
            return "rm '#{dir}' -recurse -force"
          end
          return "rm '#{dir}' -force"
        end

        def accept?(command)
          command.start_with?('rm ')
        end
      end
    end
  end
end
