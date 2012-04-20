require "vagrant"

module VagrantPlugins
  module CommandBox
    module Command
      autoload :Root,      File.expand_path("../command/root", __FILE__)
      autoload :Add,       File.expand_path("../command/add", __FILE__)
      autoload :List,      File.expand_path("../command/list", __FILE__)
      autoload :Remove,    File.expand_path("../command/remove", __FILE__)
      autoload :Repackage, File.expand_path("../command/repackage", __FILE__)
    end

    class Plugin < Vagrant.plugin("1")
      name "box command"
      description "The `box` command gives you a way to manage boxes."

      command("box") { Command::Root }
    end
  end
end
