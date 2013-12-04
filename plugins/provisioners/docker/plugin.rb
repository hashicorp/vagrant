require "vagrant"

module VagrantPlugins
  module Docker
    class Plugin < Vagrant.plugin("2")
      name "docker"
      description <<-DESC
      Provides support for provisioning your virtual machines with
      Docker images and containers.
      DESC

      config(:docker, :provisioner) do
        require_relative "config"
        Config
      end

      guest_capability("debian", "docker_install") do
        require_relative "cap/debian/docker_install"
        Cap::Debian::DockerInstall
      end

      guest_capability("debian", "docker_configure_auto_start") do
        require_relative "cap/debian/docker_configure_auto_start"
        Cap::Debian::DockerConfigureAutoStart
      end

      guest_capability("debian", "docker_configure_vagrant_user") do
        require_relative "cap/debian/docker_configure_vagrant_user"
        Cap::Debian::DockerConfigureVagrantUser
      end

      guest_capability("debian", "docker_start_service") do
        require_relative "cap/debian/docker_start_service"
        Cap::Debian::DockerStartService
      end

      guest_capability("linux", "docker_installed") do
        require_relative "cap/linux/docker_installed"
        Cap::Linux::DockerInstalled
      end

      provisioner(:docker) do
        require_relative "provisioner"
        Provisioner
      end
    end
  end
end
