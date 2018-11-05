require "vagrant"

module VagrantPlugins
  module CloudCommand
    module BoxCommand
      class Plugin < Vagrant.plugin("2")
        name "vagrant cloud box"
        description <<-DESC
        Box life cycle commands for Vagrant Cloud
        DESC

        command(:box) do
          require_relative "root"
          Command::Root
        end
      end
    end
  end
end
