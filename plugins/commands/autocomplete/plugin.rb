require "vagrant"


module VagrantPlugins
  module CommandAutocomplete
    class Plugin < Vagrant.plugin("2")
      name "autocomplete command"
      description <<-DESC
      The `autocomplete` manipulates Vagrant the autocomplete feature.
      DESC

      command("autocomplete") do
        require File.expand_path("../command/root", __FILE__)
        Command::Root
      end
    end
  end
end
