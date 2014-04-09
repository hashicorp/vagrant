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

      class BoxInvalid < HyperVError
        error_key(:box_invalid)
      end

      class IPAddrTimeout < HyperVError
        error_key(:ip_addr_timeout)
      end

      class NoSwitches < HyperVError
        error_key(:no_switches)
      end

      class PowerShellFeaturesDisabled < HyperVError
        error_key(:powershell_features_disabled)
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
