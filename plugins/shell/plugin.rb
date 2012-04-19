require "vagrant"

module VagrantPlugins
  module Shell
    autoload :Provisioner, File.expand_path("../provisioner", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "shell"
      description <<-DESC
      Provides support for provisioning your virtual machines with
      shell scripts.
      DESC

      provisioner("shell") { Provisioner }
    end
  end
end
