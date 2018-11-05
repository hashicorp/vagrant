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

      action_hook(:store_box_metadata, :machine_action_up) do |hook|
        require_relative "middleware/store_box_metadata"
        hook.append(StoreBoxMetadata)
      end
    end
  end
end
