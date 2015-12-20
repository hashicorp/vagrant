module VagrantPlugins
  module CommandPS
    module Errors
      # A convenient superclass for all our errors.
      class PSCommandError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_ps.errors")
      end

      class HostUnsupported < PSCommandError
        error_key(:host_unsupported)
      end

      class PSRemotingUndetected < PSCommandError
        error_key(:ps_remoting_undetected)
      end

      class PowerShellError < PSCommandError
        error_key(:powershell_error)
      end
    end
  end
end
