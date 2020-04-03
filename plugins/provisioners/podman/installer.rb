require_relative "../container/installer"

module VagrantPlugins
  module PodmanProvisioner
    class Installer < VagrantPlugins::ContainerProvisioner::Installer
      # This handles verifying the Podman installation, installing it if it was
      # requested, and so on. This method will raise exceptions if things are
      # wrong.
      # @params [Boolean] - if true install should use kubic project (this will)
      #                     add a yum repo.
      #                     if false install comes from default yum
      # @return [Boolean] - false if podman cannot be detected on machine, else
      #                     true if podman installs correctly or is installed
      def ensure_installed(kubic)
        if !@machine.guest.capability?(:podman_installed)
          @machine.ui.warn("Podman can not be installed")
          return false
        end

        if !@machine.guest.capability(:podman_installed)
          @machine.ui.detail("Podman installing")
          @machine.guest.capability(:podman_install, kubic)
        end

        if !@machine.guest.capability(:podman_installed)
          raise PodmanError, :install_failed
        end

        true
      end
    end
  end
end
