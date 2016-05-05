module VagrantPlugins
  module SyncedFolderSMB
    module Errors
      # A convenient superclass for all our errors.
      class SMBError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_sf_smb.errors")
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

      class ScriptError < SMBError
        error_key(:script_error)
      end

      class HostCapabilityRequired < SMBError
        error_key(:host_capability_required)
      end

      class WindowsAdminRequired < SMBError
        error_key(:windows_admin_required)
      end
    end
  end
end
