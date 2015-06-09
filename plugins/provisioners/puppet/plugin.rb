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
        require_relative "config/puppet"
        Config::Puppet
      end

      config(:puppet_server, :provisioner) do
        require_relative "config/puppet_server"
        Config::PuppetServer
      end

      provisioner(:puppet) do
        require_relative "provisioner/puppet"
        Provisioner::Puppet
      end

      provisioner(:puppet_server) do
        require_relative "provisioner/puppet_server"
        Provisioner::PuppetServer
      end
    end
  end
end
