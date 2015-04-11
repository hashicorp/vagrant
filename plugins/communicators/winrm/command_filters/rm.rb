module VagrantPlugins
  module CommunicatorWinRM
    module CommandFilters
      # Converts a *nix 'rm' command to a PowerShell equivalent
      class Rm
        def filter(command)
          # rm -Rf /some/dir
          # rm -R /some/dir
          # rm -R -f /some/dir
          # rm -f /some/dir
          # rm /some/dir
          cmd_parts = command.strip.split(/\s+/)

          # Figure out if we need to do this recursively
          recurse = false
          cmd_parts.each do |k|
            argument = k.downcase
            if argument == '-r' || argument == '-rf' || argument == '-fr'
              recurse = true
              break
            end
          end

          # Figure out which argument is the path
          dir = cmd_parts.pop
          while !dir.nil? && dir.start_with?('-')
            dir = cmd_parts.pop
          end

          ret_cmd = ''
          if recurse
            ret_cmd = "rm #{dir} -recurse -force"
          else
            ret_cmd = "rm #{dir} -force"
          end
          return ret_cmd
        end

        def accept?(command)
          command.start_with?('rm ')
        end
      end
    end
  end
end
