# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module CommunicatorWinRM
    module CommandFilters
      # Converts a *nix 'chmod' command to a PowerShell equivalent (none)
      class Chmod
        def filter(command)
          # Not supported on Windows, the communicator should skip this command
          ''
        end

        def accept?(command)
          command.start_with?('chmod ')
        end
      end
    end
  end
end
