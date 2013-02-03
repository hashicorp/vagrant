require "json"

module VagrantPlugins
  module CommandPlugin
    # This is a helper to deal with the plugin state file that Vagrant
    # uses to track what plugins are installed and activated and such.
    class StateFile
      def initialize(path)
        @path = path

        @data = {}
        @data = JSON.parse(@path.read) if @path.exist?
        @data["installed"] ||= []
      end

      # Add a plugin that is installed to the state file.
      #
      # @param [String] name The name of the plugin
      def add_plugin(name)
        if !@data["installed"].include?(name)
          @data["installed"] << name
        end

        save!
      end

      # This returns a list of installed plugins according to the state
      # file. Note that this may _not_ directly match over to actually
      # installed gems.
      #
      # @return [Array<String>]
      def installed_plugins
        @data["installed"]
      end

      # Remove a plugin that is installed from the state file.
      #
      # @param [String] name The name of the plugin.
      def remove_plugin(name)
        @data["installed"].delete(name)
        save!
      end

      # This saves the state back into the state file.
      def save!
        # Scrub some fields
        @data["installed"].sort!
        @data["installed"].uniq!

        # Save
        @path.open("w+") do |f|
          f.write(JSON.dump(@data))
        end
      end
    end
  end
end
