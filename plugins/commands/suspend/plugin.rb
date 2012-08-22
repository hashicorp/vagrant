require "vagrant"

module VagrantPlugins
  module CommandSuspend
    class Plugin < Vagrant.plugin("1")
      name "suspend command"
      description <<-DESC
      The `suspend` command suspends a running virtual machine.
      DESC

      command("suspend") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end
