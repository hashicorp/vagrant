module VagrantPlugins
  module CommunicatorWinRM
    module Errors
      # A convenient superclass for all our errors.
      class WinRMError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_winrm.errors")
      end

      class AuthError < WinRMError
        error_key(:auth_error)
      end

      class ExecutionError < WinRMError
        error_key(:execution_error)
      end

      class InvalidShell < WinRMError
        error_key(:invalid_shell)
      end

      class WinRMNotReady < WinRMError
        error_key(:winrm_not_ready)
      end

      class WinRMFileTransferError < WinRMError
        error_key(:winrm_file_transfer_error)
      end
    end
  end
end
