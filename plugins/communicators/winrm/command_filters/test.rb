module VagrantPlugins
  module CommunicatorWinRM
    module CommandFilters

      # Converts a *nix 'test' command to a PowerShell equivalent
      class Test

        def filter(command)
          # test -d /tmp/dir
          # test -f /tmp/afile
          # test -L /somelink
          # test -x /tmp/some.exe
          
          cmd_parts = command.strip.split(/\s+/)
          if cmd_parts[1] == '-d'
            # ensure it exists and is a directory
            return "if ((Test-Path '#{cmd_parts[2]}') -and (get-item '#{cmd_parts[2]}').PSIsContainer) { exit 0 } exit 1"
          elsif cmd_parts[1] == '-f' || cmd_parts[1] == '-x'
            # ensure it exists and is a file
            return "if ((Test-Path '#{cmd_parts[2]}') -and (!(get-item '#{cmd_parts[2]}').PSIsContainer)) { exit 0 } exit 1"
          end

          # otherwise, just check for existence
          return "if (Test-Path '#{cmd_parts[2]}') { exit 0 } exit 1"
        end

        # if (Test-Path 'c:\windows' && (get-item 'c:\windows').PSIsContainer) { Write-Host 0 } Write-Host 1

        def accept?(command)
          command.start_with?('test ')
        end

      end

    end
  end
end
