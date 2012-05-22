require "vagrant"

module VagrantPlugins
  module CommandSuspend
    class Plugin < Vagrant.plugin("1")
      name "suspend command"
      description <<-DESC
      The `suspend` command suspends a running virtual machine.
      DESC

      activated do
        require File.expand_path("../command", __FILE__)
      end

      command("suspend") { Command }
    end
  end
end
