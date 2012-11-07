require "vagrant"

module VagrantPlugins
  module CommandProvision
    class Plugin < Vagrant.plugin("2")
      name "provision command"
      description <<-DESC
      The `provision` command provisions your virtual machine based on the
      configuration of the Vagrantfile.
      DESC

      command("provision") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end
