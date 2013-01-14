require "vagrant"

module VagrantPlugins
  module Puppet
    class Plugin < Vagrant.plugin("2")
      name "puppet"
      description <<-DESC
      Provides support for provisioning your virtual machines with
      Puppet either using `puppet apply` or a Puppet server.
      DESC

      config(:puppet, :provisioner) do
        require File.expand_path("../config/puppet", __FILE__)
        Config::Puppet
      end

      config(:puppet_server, :provisioner) do
        require File.expand_path("../config/puppet_server", __FILE__)
        Config::PuppetServer
      end

      provisioner(:puppet) do
        require File.expand_path("../provisioner/puppet", __FILE__)
        Provisioner::Puppet
      end

      provisioner(:puppet_server) do
        require File.expand_path("../provisioner/puppet_server", __FILE__)
        Provisioner::PuppetServer
      end
    end
  end
end
