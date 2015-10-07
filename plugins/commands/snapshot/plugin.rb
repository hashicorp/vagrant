require "vagrant"

module VagrantPlugins
  module CommandSnapshot
    class Plugin < Vagrant.plugin("2")
      name "snapshot command"
      description "The `snapshot` command gives you a way to manage snapshots."

      command("snapshot") do
        require File.expand_path("../command/root", __FILE__)
        Command::Root
      end
    end
  end
end
