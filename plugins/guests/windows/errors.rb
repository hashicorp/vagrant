module VagrantPlugins
  module GuestWindows
    module Errors
      # A convenient superclass for all our errors.
      class WindowsError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_windows.errors")
      end

      class CantReadMACAddresses < WindowsError
        error_key(:cant_read_mac_addresses)
      end

      class NetworkWinRMRequired < WindowsError
        error_key(:network_winrm_required)
      end

      class RenameComputerFailed < WindowsError
        error_key(:rename_computer_failed)
      end
    end
  end
end
