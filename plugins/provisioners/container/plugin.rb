require "vagrant"

module VagrantPlugins
  module ContainerProvisioner
    class Plugin < Vagrant.plugin("2")
      name "container"
      description <<-DESC
      Provides support for provisioning your virtual machines with
      OCI images and containers.
      DESC

      config(:container, :provisioner) do
        require_relative "config"
        Config
      end

      provisioner(:container) do
        require_relative "provisioner"
        Provisioner
      end
    end
  end
end
