require "vagrant/config/v1/root"

module Vagrant
  module Config
    # This is the "version 1" configuration loader.
    class V1
      # Loads the configuration for the given proc and returns a configuration
      # object.
      #
      # @param [Proc] config_proc
      # @return [Object]
      def self.load(config_proc)
        # Get all the registered plugins
        config_map = {}
        Vagrant.plugin("1").registered.each do |plugin|
          plugin.config.each do |key, klass|
            config_map[key] = klass
          end
        end

        # Create the configuration root object
        root = V1::Root.new(config_map)

        # Call the proc with the root
        config_proc.call(root)

        # Return the root object, which doubles as the configuration object
        # we actually use for accessing as well.
        root
      end
    end
  end
end
