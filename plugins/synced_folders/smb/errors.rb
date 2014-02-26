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
    end
  end
end
