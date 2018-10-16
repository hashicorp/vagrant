require "vagrant"

module VagrantPlugins
  module CloudCommand
    module VersionCommand
      class Plugin < Vagrant.plugin("2")
        name "vagrant cloud version"
        description <<-DESC
        Version life cycle commands for Vagrant Cloud
        DESC

        command(:version) do
          require_relative "root"
          Command::Root
        end
      end
    end
  end
end
