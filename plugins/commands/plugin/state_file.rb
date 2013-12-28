require "json"

module VagrantPlugins
  module CommandPlugin
    # This is a helper to deal with the plugin state file that Vagrant
    # uses to track what plugins are installed and activated and such.
    class StateFile
      def initialize(path)
        @path = path

        @data = {}
        if @path.exist?
          begin
            @data = JSON.parse(@path.read)
          rescue JSON::ParserError => e
            raise Vagrant::Errors::PluginStateFileParseError,
              :path => path, :message => e.message
          end

          upgrade_v0! if !@data["version"]
        end

        @data["version"] ||= "1"
        @data["installed"] ||= {}
      end

      # Add a plugin that is installed to the state file.
      #
      # @param [String] name The name of the plugin
      def add_plugin(name)
        if !@data["installed"].has_key?(name)
          @data["installed"][name] = {
            "ruby_version"    => RUBY_VERSION,
            "vagrant_version" => Vagrant::VERSION,
          }
        end

        save!
      end

      # This returns a hash of installed plugins according to the state
      # file. Note that this may _not_ directly match over to actually
      # installed gems.
      #
      # @return [Hash]
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
        @path.open("w+") do |f|
          f.write(JSON.dump(@data))
        end
      end

      protected

      # This upgrades the internal data representation from V0 (the initial
      # version) to V1.
      def upgrade_v0!
        @data["version"] = "1"

        new_installed = {}
        (@data["installed"] || []).each do |plugin|
          new_installed[plugin] = {
            "ruby_version"    => "0",
            "vagrant_version" => "0",
          }
        end

        @data["installed"] = new_installed

        save!
      end
    end
  end
end
