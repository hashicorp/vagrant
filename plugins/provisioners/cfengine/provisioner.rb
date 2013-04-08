require "vagrant"

module VagrantPlugins
  module CFEngine
    class Provisioner < Vagrant.plugin("2", :provisioner)
      def provision
        handle_cfengine_installation
      end

      protected

      # This handles verifying the CFEngine installation, installing it
      # if it was requested, and so on. This method will raise exceptions
      # if things are wrong.
      def handle_cfengine_installation
        if !@machine.guest.capability?(:cfengine_installed)
          @machine.ui.warn(I18n.t("vagrant.cfengine_cant_detect"))
          return
        end

        installed = @machine.guest.capability(:cfengine_installed)
        if !installed || @config.install == :force
          raise Vagrant::Errors::CFEngineNotInstalled if !@config.install

          @machine.ui.info(I18n.t("vagrant.cfengine_installing"))
          @machine.guest.capability(:cfengine_install, @config)

          if !@machine.guest.capability(:cfengine_installed)
            raise Vagrant::Errors::CFEngineInstallFailed
          end
        end
      end
    end
  end
end
