require "vagrant"

module VagrantPlugins
  module CommandStatus
    autoload :Command, File.expand_path("../command", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "status command"
      description <<-DESC
      The `status` command shows the status of all your virtual machines
      in this environment.
      DESC

      command("status") { Command }
    end
  end
end
