
require "vagrant"

module VagrantPlugins
  module CloudCommand
    module AuthCommand
      class Plugin < Vagrant.plugin("2")
        name "vagrant cloud auth"
        description <<-DESC
        Authorization commands for Vagrant Cloud
        DESC

        command(:auth) do
          require_relative "root"
          Command::Root
        end
      end
    end
  end
end
