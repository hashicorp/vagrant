require "pathname"

require "vagrant"

require_relative "command_builder"

module VagrantPlugins
  module Chef
    class Plugin < Vagrant.plugin("2")
      name "chef"
      description <<-DESC
      Provides support for provisioning your virtual machines with
      Chef via `chef-solo`, `chef-client`, or `chef-apply`.
      DESC

      config(:chef_apply, :provisioner) do
        require_relative "config/chef_apply"
        Config::ChefApply
      end

      config(:chef_client, :provisioner) do
        require_relative "config/chef_client"
        Config::ChefClient
      end

      config(:chef_solo, :provisioner) do
        require_relative "config/chef_solo"
        Config::ChefSolo
      end

      config(:chef_zero, :provisioner) do
        require_relative "config/chef_zero"
        Config::ChefZero
      end

      provisioner(:chef_apply) do
        require_relative "provisioner/chef_apply"
        Provisioner::ChefApply
      end

      provisioner(:chef_client) do
        require_relative "provisioner/chef_client"
        Provisioner::ChefClient
      end

      provisioner(:chef_solo)   do
        require_relative "provisioner/chef_solo"
        Provisioner::ChefSolo
      end

      provisioner(:chef_zero)   do
        require_relative "provisioner/chef_zero"
        Provisioner::ChefZero
      end

      guest_capability(:linux, :chef_installed) do
        require_relative "cap/linux/chef_installed"
        Cap::Linux::ChefInstalled
      end

      guest_capability(:debian, :chef_install) do
        require_relative "cap/debian/chef_install"
        Cap::Debian::ChefInstall
      end

      guest_capability(:redhat, :chef_install) do
        require_relative "cap/redhat/chef_install"
        Cap::Redhat::ChefInstall
      end
    end
  end
end
