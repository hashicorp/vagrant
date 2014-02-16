module VagrantPlugins
  module HyperV
    module Errors
      # A convenient superclass for all our errors.
      class HyperVError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_hyperv.errors")
      end

      class PowerShellRequired < HyperVError
        error_key(:powershell_required)
      end
    end
  end
end
