require "vagrant"

module VagrantPlugins
  module CommandSuspend
    class Plugin < Vagrant.plugin("2")
      name "suspend command"
      description <<-DESC
      The `suspend` command suspends execution and puts it to sleep.
      The command `resume` returns it to running status.
      DESC

      command("suspend") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end
