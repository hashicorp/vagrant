require "vagrant"

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
