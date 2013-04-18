begin
  require "vagrant"
rescue LoadError
  raise "The Vagrant Salt plugin must be run within Vagrant."
end

if Vagrant::VERSION < "1.1.0"
  raise "Please install vagrant-salt gem <=0.3.4 for Vagrant < 1.1.0"
end

module VagrantPlugins
  module Salt
    class Plugin < Vagrant.plugin("2")
      name "salt"
      description <<-DESC
      Provisions virtual machines using SaltStack
      DESC

      config(:salt, :provisioner) do
        require File.expand_path("../config", __FILE__)
        Config
      end

      provisioner(:salt) do
        require File.expand_path("../provisioner", __FILE__)
        Provisioner
      end

    end
  end
end