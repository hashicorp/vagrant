require "vagrant"

module VagrantPlugins
  module CommandBox
    class Plugin < Vagrant.plugin("1")
      name "box command"
      description "The `box` command gives you a way to manage boxes."

      activated do
        require File.expand_path("../command/root", __FILE__)
        require File.expand_path("../command/add", __FILE__)
        require File.expand_path("../command/list", __FILE__)
        require File.expand_path("../command/remove", __FILE__)
        require File.expand_path("../command/repackage", __FILE__)
      end

      command("box") { Command::Root }
    end
  end
end
