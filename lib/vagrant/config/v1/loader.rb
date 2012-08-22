require "vagrant/config/v1/root"

module Vagrant
  module Config
    module V1
      # This is the loader that handles configuration loading for V1
      # configurations.
      class Loader < VersionBase
        # Returns a bare empty configuration object.
        #
        # @return [V1::Root]
        def self.init
          new_root_object
        end

        # Finalizes the configuration by making sure there is at least
        # one VM defined in it.
        def self.finalize(config)
          # Call the `#finalize` method on each of the configuration keys.
          # They're expected to modify themselves in our case.
          config.finalize!

          # Return the object
          config
        end

        # Loads the configuration for the given proc and returns a configuration
        # object.
        #
        # @param [Proc] config_proc
        # @return [Object]
        def self.load(config_proc)
          # Create a root configuration object
          root = new_root_object

          # Call the proc with the root
          config_proc.call(root)

          # Return the root object, which doubles as the configuration object
          # we actually use for accessing as well.
          root
        end

        # Merges two configuration objects.
        #
        # @param [V1::Root] old The older root config.
        # @param [V1::Root] new The newer root config.
        # @return [V1::Root]
        def self.merge(old, new)
          # Grab the internal states, we use these heavily throughout the process
          old_state = old.__internal_state
          new_state = new.__internal_state

          # The config map for the new object is the old one merged with the
          # new one.
          config_map = old_state["config_map"].merge(new_state["config_map"])

          # Merge the keys.
          old_keys = old_state["keys"]
          new_keys = new_state["keys"]
          keys     = {}
          old_keys.each do |key, old|
            if new_keys.has_key?(key)
              # We need to do a merge, which we expect to be available
              # on the config class itself.
              keys[key] = old.merge(new_keys[key])
            else
              # We just take the old value, but dup it so that we can modify.
              keys[key] = old.dup
            end
          end

          new_keys.each do |key, new|
            # Add in the keys that the new class has that we haven't merged.
            if !keys.has_key?(key)
              keys[key] = new.dup
            end
          end

          # Return the final root object
          V1::Root.new(config_map, keys)
        end

        protected

        def self.new_root_object
          # Get all the registered plugins
          config_map = {}
          Vagrant.plugin("1").registered.each do |plugin|
            # Activate the plugin since we're about to use it
            plugin.activate!

            # Get all the available configuration keys and add them to the map
            plugin.config.each do |key, klass|
              config_map[key] = klass
            end
          end

          # Create the configuration root object
          V1::Root.new(config_map)
        end
      end
    end
  end
end
