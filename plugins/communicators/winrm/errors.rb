module VagrantPlugins
  module CommunicatorWinRM
    module Errors
      # A convenient superclass for all our errors.
      class WinRMError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_winrm.errors")
      end

      class TransientError < WinRMError
      end

      class AuthenticationFailed < WinRMError
        error_key(:authentication_failed)
      end

      class ExecutionError < WinRMError
        error_key(:execution_error)
      end

      class InvalidShell < WinRMError
        error_key(:invalid_shell)
      end

      class WinRMBadExitStatus < WinRMError
        error_key(:winrm_bad_exit_status)
      end

      class WinRMNotReady < WinRMError
        error_key(:winrm_not_ready)
      end

      class WinRMFileTransferError < WinRMError
        error_key(:winrm_file_transfer_error)
      end

      class InvalidTransport < WinRMError
        error_key(:invalid_transport)
      end

      class SSLError < WinRMError
        error_key(:ssl_error)
      end

      class ConnectionTimeout < TransientError
        error_key(:connection_timeout)
      end

      class Disconnected < TransientError
        error_key(:disconnected)
      end

      class ConnectionRefused < TransientError
        error_key(:connection_refused)
      end

      class ConnectionReset < TransientError
        error_key(:connection_reset)
      end

      class HostDown < TransientError
        error_key(:host_down)
      end

      class NoRoute < TransientError
        error_key(:no_route)
      end
    end
  end
end
