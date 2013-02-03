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
      end

      # Add a plugin that is installed to the state file.
      #
      # @param [String] name The name of the plugin
      def add_plugin(name)
        @data["installed"] ||= []
        @data["installed"] << name
        save!
      end

      # This saves the state back into the state file.
      def save!
        @path.open("w+") do |f|
          f.write(JSON.dump(@data))
        end
      end
    end
  end
end
