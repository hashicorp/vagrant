require "vagrant"

module VagrantPlugins
  module Chef
    class Plugin < Vagrant.plugin("1")
      name "chef"
      description <<-DESC
      Provides support for provisioning your virtual machines with
      Chef via `chef-solo` or `chef-client`.
      DESC

      provisioner("chef_solo")   do
        require File.expand_path("../provisioner/chef_solo", __FILE__)
        Provisioner::ChefSolo
      end

      provisioner("chef_client") do
        require File.expand_path("../provisioner/chef_client", __FILE__)
        Provisioner::ChefClient
      end
    end
  end
end
