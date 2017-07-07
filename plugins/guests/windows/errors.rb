module VagrantPlugins
  module GuestWindows
    module Errors
      # A convenient superclass for all our errors.
      class WindowsError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_windows.errors")
      end

      class NetworkWinRMRequired < WindowsError
        error_key(:network_winrm_required)
      end

      class RenameComputerFailed < WindowsError
        error_key(:rename_computer_failed)
      end

      class PublicKeyDirectoryFailure < WindowsError
        error_key(:public_key_directory_failure)
      end
    end
  end
end
