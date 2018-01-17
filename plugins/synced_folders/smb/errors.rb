module VagrantPlugins
  module SyncedFolderSMB
    module Errors
      # A convenient superclass for all our errors.
      class SMBError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_sf_smb.errors")
      end

      class SMBNotSupported < SMBError
        error_key(:not_supported)
      end

      class SMBStartFailed < SMBError
        error_key(:start_failed)
      end

      class SMBCredentialsMissing < SMBError
        error_key(:credentials_missing)
      end

      class SMBListFailed < SMBError
        error_key(:list_failed)
      end

      class SMBNameError < SMBError
        error_key(:name_error)
      end

      class CredentialsRequestError < SMBError
        error_key(:credentials_request_error)
      end

      class DefineShareFailed < SMBError
        error_key(:define_share_failed)
      end

      class PruneShareFailed < SMBError
        error_key(:prune_share_failed)
      end

      class NoHostIPAddr < SMBError
        error_key(:no_routable_host_addr)
      end

      class PowershellError < SMBError
        error_key(:powershell_error)
      end

      class PowershellVersion < SMBError
        error_key(:powershell_version)
      end

      class WindowsHostRequired < SMBError
        error_key(:windows_host_required)
      end

      class WindowsAdminRequired < SMBError
        error_key(:windows_admin_required)
      end
    end
  end
end
