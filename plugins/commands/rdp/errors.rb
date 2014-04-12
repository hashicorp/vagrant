module VagrantPlugins
  module CommandRDP
    module Errors
      # A convenient superclass for all our errors.
      class RDPError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_rdp.errors")
      end

      class HostUnsupported < RDPError
        error_key(:host_unsupported)
      end

      class RDPUndetected < RDPError
        error_key(:rdp_undetected)
      end
    end
  end
end
