require "vagrant"

module VagrantPlugins
  module CommandValidate
    class Plugin < Vagrant.plugin("2")
      name "validate command"
      description <<-DESC
      The `validate` command validates the Vagrantfile.
      DESC

      command("validate") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end
