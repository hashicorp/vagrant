require "vagrant"

module VagrantPlugins
  module CommandUp
    autoload :Command,     File.expand_path("../command", __FILE__)
    autoload :StartMixins, File.expand_path("../start_mixins", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "up command"
      description <<-DESC
      The `up` command brings the virtual environment up and running.
      DESC

      command("up") { Command }
    end
  end
end
