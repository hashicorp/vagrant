module VagrantPlugins
  module CommandRDP
    module Errors
      # A convenient superclass for all our errors.
      class RDPError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_rdp.errors")
      end

      class GuestUnsupported < RDPError
        error_key(:guest_unsupported)
      end

      class HostUnsupported < RDPError
        error_key(:host_unsupported)
      end
    end
  end
end
