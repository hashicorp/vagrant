require "vagrant"

module VagrantPlugins
  module CommandPristine
    class Plugin < Vagrant.plugin("2")
      name "pristine command"
      description <<-DESC
      The `pristine` command is a shortcut for running `destroy` and `up`
      DESC

      command("pristine") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end
