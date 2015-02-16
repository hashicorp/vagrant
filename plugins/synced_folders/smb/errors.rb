module VagrantPlugins
  module SyncedFolderSMB
    module Errors
      # A convenient superclass for all our errors.
      class SMBError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_sf_smb.errors")
      end

      class DarwinVersion < SMBError
        error_key(:darwin_version)
      end

      class DefineShareFailed < SMBError
        error_key(:define_share_failed)
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

      class WindowsDarwinHostRequired < SMBError
        error_key(:windows_darwin_host_required)
      end

      class WindowsAdminRequired < SMBError
        error_key(:windows_admin_required)
      end
    end
  end
end
