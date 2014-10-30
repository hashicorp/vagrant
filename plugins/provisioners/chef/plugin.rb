require "pathname"

require "vagrant"

require_relative "command_builder"

module VagrantPlugins
  module Chef
    class Plugin < Vagrant.plugin("2")
      name "chef"
      description <<-DESC
      Provides support for provisioning your virtual machines with
      Chef via `chef-solo` or `chef-client`.
      DESC

      config(:chef_solo, :provisioner) do
        require_relative "config/chef_solo"
        Config::ChefSolo
      end

      config(:chef_client, :provisioner) do
        require_relative "config/chef_client"
        Config::ChefClient
      end

      config(:chef_zero, :provisioner) do
        require_relative "config/chef_zero"
        Config::ChefZero
      end

      provisioner(:chef_solo)   do
        require_relative "provisioner/chef_solo"
        Provisioner::ChefSolo
      end

      provisioner(:chef_client) do
        require_relative "provisioner/chef_client"
        Provisioner::ChefClient
      end

      provisioner(:chef_zero)   do
        require_relative "provisioner/chef_zero"
        Provisioner::ChefZero
      end
    end
  end
end
