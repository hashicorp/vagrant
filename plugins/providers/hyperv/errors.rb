module VagrantPlugins
  module HyperV
    module Errors
      # A convenient superclass for all our errors.
      class HyperVError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_hyperv.errors")
      end

      class AdminRequired < HyperVError
        error_key(:admin_required)
      end

      class PowerShellError < HyperVError
        error_key(:powershell_error)
      end

      class PowerShellRequired < HyperVError
        error_key(:powershell_required)
      end

      class WindowsRequired < HyperVError
        error_key(:windows_required)
      end
    end
  end
end
