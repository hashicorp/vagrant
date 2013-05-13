require "vagrant"

module VagrantPlugins
  module CommandInit
    class Plugin < Vagrant.plugin("2")
      name "init command"
      description <<-DESC
      The `init` command sets up your working directory to be a
      Vagrant-managed environment.
      DESC

      command("init") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end
