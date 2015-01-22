module VagrantPlugins
  module Chef
    class Installer
      def initialize(machine, options = {})
        @machine    = machine
        @version    = options.fetch(:version, :latest)
        @prerelease = options.fetch(:prerelease, :latest)
        @force      = options.fetch(:force, false)
        @download_path  = options.fetch(:download_path, nil)
      end

      # This handles verifying the Chef installation, installing it if it was
      # requested, and so on. This method will raise exceptions if things are
      # wrong.
      def ensure_installed
        # If the guest cannot check if Chef is installed, just exit printing a
        # warning...
        if !@machine.guest.capability?(:chef_installed)
          @machine.ui.warn(I18n.t("vagrant.chef_cant_detect"))
          return
        end

        if !should_install_chef?
          @machine.ui.info(I18n.t("vagrant.chef_already_installed",
            version: @version.to_s))
          return
        end

        @machine.ui.detail(I18n.t("vagrant.chef_installing",
          version: @version.to_s))
        @machine.guest.capability(:chef_install, @version, @prerelease, @download_path)

        if !@machine.guest.capability(:chef_installed, @version)
          raise Provisioner::Base::ChefError, :install_failed
        end
      end

      # Determine if Chef should be installed. Chef is installed if the "force"
      # option is given or if the guest does not have Chef installed at the
      # proper version.
      def should_install_chef?
        @force || !@machine.guest.capability(:chef_installed, @version)
      end
    end
  end
end
