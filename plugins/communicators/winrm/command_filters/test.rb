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
          flag = cmd_parts[1]
          path = cmd_parts[2]

          if flag == '-d'
            check_for_directory(path)
          elsif flag == '-f' || flag == '-x'
            check_for_file(path)
          else
            check_exists(path)
          end
        end

        def accept?(command)
          command.start_with?("test ")
        end

        private

        def check_for_directory(path)
          <<-EOH
            $p = "#{path}"
            if ((Test-Path $p) -and (get-item $p).PSIsContainer) {
              exit 0
            }
            exit 1
          EOH
        end

        def check_for_file(path)
          <<-EOH
            $p = "#{path}"
            if ((Test-Path $p) -and (!(get-item $p).PSIsContainer)) {
              exit 0
            }
            exit 1
          EOH
        end

        def check_exists(path)
          <<-EOH
            $p = "#{path}"
            if (Test-Path $p) {
              exit 0
            }
            exit 1
          EOH
        end
      end
    end
  end
end
