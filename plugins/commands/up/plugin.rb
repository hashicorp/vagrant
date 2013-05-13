require "vagrant"

module VagrantPlugins
  module CommandUp
    class Plugin < Vagrant.plugin("2")
      name "up command"
      description <<-DESC
      The `up` command brings the virtual environment up and running.
      DESC

      command("up") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end
