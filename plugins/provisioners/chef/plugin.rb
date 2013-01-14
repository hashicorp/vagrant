require "vagrant"

module VagrantPlugins
  module Chef
    class Plugin < Vagrant.plugin("2")
      name "chef"
      description <<-DESC
      Provides support for provisioning your virtual machines with
      Chef via `chef-solo` or `chef-client`.
      DESC

      config(:chef_solo, :provisioner) do
        require File.expand_path("../config/chef_solo", __FILE__)
        Config::ChefSolo
      end

      config(:chef_client, :provisioner) do
        require File.expand_path("../config/chef_client", __FILE__)
        Config::ChefClient
      end

      provisioner(:chef_solo)   do
        require File.expand_path("../provisioner/chef_solo", __FILE__)
        Provisioner::ChefSolo
      end

      provisioner(:chef_client) do
        require File.expand_path("../provisioner/chef_client", __FILE__)
        Provisioner::ChefClient
      end
    end
  end
end
