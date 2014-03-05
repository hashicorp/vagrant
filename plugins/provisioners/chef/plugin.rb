require "pathname"

require "vagrant"

module VagrantPlugins
  module Chef
    root = Pathname.new(File.expand_path("../", __FILE__))
    autoload :CommandBuilder, root.join("command_builder")

    class Plugin < Vagrant.plugin("2")
      name "chef"
      description <<-DESC
      Provides support for provisioning your virtual machines with
      Chef via `chef-solo`, `chef-client` or `chef-zero`.
      DESC

      config(:chef_solo, :provisioner) do
        require File.expand_path("../config/chef_solo", __FILE__)
        Config::ChefSolo
      end

      config(:chef_client, :provisioner) do
        require File.expand_path("../config/chef_client", __FILE__)
        Config::ChefClient
      end

      config(:chef_zero, :provisioner) do
        require File.expand_path("../config/chef_zero", __FILE__)
        Config::ChefZero
      end

      provisioner(:chef_solo)   do
        require File.expand_path("../provisioner/chef_solo", __FILE__)
        Provisioner::ChefSolo
      end

      provisioner(:chef_client) do
        require File.expand_path("../provisioner/chef_client", __FILE__)
        Provisioner::ChefClient
      end

      provisioner(:chef_zero) do
        require File.expand_path("../provisioner/chef_zero", __FILE__)
        Provisioner::ChefZero
      end
    end
  end
end
