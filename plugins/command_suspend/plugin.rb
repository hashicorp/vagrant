require "vagrant"

module VagrantPlugins
  module CommandSuspend
    autoload :Command, File.expand_path("../command", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "suspend command"
      description <<-DESC
      The `suspend` command suspends a running virtual machine.
      DESC

      command("suspend") { Command }
    end
  end
end
