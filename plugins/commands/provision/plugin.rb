require "vagrant"

module VagrantPlugins
  module CommandProvision
    class Plugin < Vagrant.plugin("1")
      name "provision command"
      description <<-DESC
      The `provision` command provisions your virtual machine based on the
      configuration of the Vagrantfile.
      DESC

      activated do
        require File.expand_path("../command", __FILE__)
      end

      command("provision") { Command }
    end
  end
end
