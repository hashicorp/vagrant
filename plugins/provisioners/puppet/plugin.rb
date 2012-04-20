require "vagrant"

module VagrantPlugins
  module Pupppet
    module Provisioner
      autoload :Puppet,   File.expand_path("../provisioner/puppet", __FILE__)
      autoload :PuppetServer, File.expand_path("../provisioner/puppet_server", __FILE__)
    end

    class Plugin < Vagrant.plugin("1")
      name "puppet"
      description <<-DESC
      Provides support for provisioning your virtual machines with
      Puppet either using `puppet apply` or a Puppet server.
      DESC

      provisioner("puppet")        { Provisioner::Puppet }
      provisioner("puppet_server") { Provisioner::PuppetServer }
    end
  end
end
