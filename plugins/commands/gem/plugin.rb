require "vagrant"

module VagrantPlugins
  module CommandGem
    class Plugin < Vagrant.plugin("1")
      name "gem command"
      description <<-DESC
      Provides an interface to RubyGems that can be used to install
      RubyGems into the Vagrant environment.
      DESC

      command("gem") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end
