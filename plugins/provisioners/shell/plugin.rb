require "vagrant"

module VagrantPlugins
  module Shell
    class Plugin < Vagrant.plugin("1")
      name "shell"
      description <<-DESC
      Provides support for provisioning your virtual machines with
      shell scripts.
      DESC

      provisioner("shell") do
        require File.expand_path("../provisioner", __FILE__)
        Provisioner
      end
    end
  end
end
