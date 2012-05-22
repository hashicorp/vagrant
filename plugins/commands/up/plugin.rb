require "vagrant"

# These are used by various other commands, so we just load them
# up right away.
require File.expand_path("../start_mixins", __FILE__)

module VagrantPlugins
  module CommandUp
    class Plugin < Vagrant.plugin("1")
      name "up command"
      description <<-DESC
      The `up` command brings the virtual environment up and running.
      DESC

      activated do
        require File.expand_path("../command", __FILE__)
      end

      command("up") { Command }
    end
  end
end
