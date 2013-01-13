require "vagrant"

module VagrantPlugins
  module Shell
    class Plugin < Vagrant.plugin("2")
      name "shell"
      description <<-DESC
      Provides support for provisioning your virtual machines with
      shell scripts.
      DESC

      config(:shell, :provisioner) do
        require File.expand_path("../config", __FILE__)
        Config
      end

      provisioner(:shell) do
        require File.expand_path("../provisioner", __FILE__)
        Provisioner
      end
    end
  end
end
