require "vagrant"

module VagrantPlugins
  module CommandBox
    class Plugin < Vagrant.plugin("2")
      name "box command"
      description "The `box` command gives you a way to manage boxes."

      command("box") do
        require File.expand_path("../command/root", __FILE__)
        Command::Root
      end
    end
  end
end
