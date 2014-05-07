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
    end
  end
end
