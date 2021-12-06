module Vagrant
  module Plugin
    module Remote
      # This is the wrapper class for all Remote plugins.
      class Plugin < Vagrant::Plugin::V2::Plugin

        # This returns the manager for all Remote plugins.
        #
        # @return [Remote::Manager]
        def self.manager
          @manager ||= Manager.new
        end

        # Returns the {Components} for this plugin.
        #
        # @return [Components]
        def self.components
          @components ||= Vagrant::Plugin::V2::Components.new
        end
      end
    end
  end
end
