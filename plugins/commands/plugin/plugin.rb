require "vagrant"

module VagrantPlugins
  module CommandPlugin
    class Plugin < Vagrant.plugin("2")
      name "plugin command"
      description <<-DESC
      This command helps manage and install plugins within the
      Vagrant environment.
DESC

      command("plugin") do
        require File.expand_path("../command/root", __FILE__)
        Command::Root
      end
    end

    autoload :Action, File.expand_path("../action", __FILE__)
    autoload :GemHelper, File.expand_path("../gem_helper", __FILE__)
    autoload :StateFile, File.expand_path("../state_file", __FILE__)
  end
end
