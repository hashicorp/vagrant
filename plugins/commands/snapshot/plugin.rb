# coding: utf-8
module VagrantPlugins
  module CommandSnapshot
    class Plugin < Vagrant.plugin('2')
      description <<-DESC
        This command helps manage snapshots within the Vagrant
        environment if the guest provider has that capability.
DESC
      command('snapshot') do
        require File.expand_path('../commands/root', __FILE__)
        Command::Root
      end
    end
  end
end
