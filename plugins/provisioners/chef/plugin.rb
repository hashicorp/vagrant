require "vagrant"

module VagrantPlugins
  module Chef
    module Provisioner
      autoload :ChefSolo,   File.expand_path("../provisioner/chef_solo", __FILE__)
      autoload :ChefClient, File.expand_path("../provisioner/chef_client", __FILE__)
    end

    class Plugin < Vagrant.plugin("1")
      name "chef"
      description <<-DESC
      Provides support for provisioning your virtual machines with
      Chef via `chef-solo` or `chef-client`.
      DESC

      provisioner("chef_solo")   { Provisioner::ChefSolo }
      provisioner("chef_client") { Provisioner::ChefClient }
    end
  end
end
