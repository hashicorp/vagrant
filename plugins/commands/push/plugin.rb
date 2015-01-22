require "vagrant"

module VagrantPlugins
  module CommandPush
    class Plugin < Vagrant.plugin("2")
      name "push command"
      description <<-DESC
      The `push` command deploys code in this environment.
      DESC

      command("push") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end
