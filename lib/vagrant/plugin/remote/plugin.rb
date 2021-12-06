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
      end
    end
  end
end
