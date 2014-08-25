module VagrantPlugins
  module CommandPS
    module Errors
      # A convenient superclass for all our errors.
      class PSError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_ps.errors")
      end

      class HostUnsupported < PSError
        error_key(:host_unsupported)
      end

      class PSRemotingUndetected < PSError
        error_key(:ps_remoting_undetected)
      end
    end
  end
end
