module VagrantPlugins
  module DockerProvisioner
    class Installer
      def initialize(machine, version)
        @machine = machine
        @version = version
      end

      # This handles verifying the Docker installation, installing it if it was
      # requested, and so on. This method will raise exceptions if things are
      # wrong.
      def ensure_installed
        if !@machine.guest.capability?(:docker_installed)
          @machine.ui.warn(I18n.t("vagrant.docker_cant_detect"))
          return
        end

        if !@machine.guest.capability(:docker_installed)
          @machine.ui.detail(I18n.t("vagrant.docker_installing", version: @version.to_s))
          @machine.guest.capability(:docker_install, @version)

          if !@machine.guest.capability(:docker_installed)
            raise DockerError, :install_failed
          end
        end

        if @machine.guest.capability?(:docker_configure_vagrant_user)
          @machine.guest.capability(:docker_configure_vagrant_user)
        end
      end
    end
  end
end
