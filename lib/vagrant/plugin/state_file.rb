require "json"
require "fileutils"
require "tempfile"

module Vagrant
  module Plugin
    # This is a helper to deal with the plugin state file that Vagrant
    # uses to track what plugins are installed and activated and such.
    class StateFile

      # @return [Pathname] path to file
      attr_reader :path

      def initialize(path)
        @path = path

        @data = {}
        if @path.exist?
          begin
            @data = JSON.parse(@path.read)
          rescue JSON::ParserError => e
            raise Vagrant::Errors::PluginStateFileParseError,
              path: path, message: e.message
          end

          upgrade_v0! if !@data["version"]
          upgrade_v1! if @data["version"].to_s == "1"
        end

        @data["version"] ||= "2"
        @data["ruby"] ||= {"installed" => {}}
        @data["go_plugin"] ||= {}
      end

      # Add a go plugin that is installed to the state file.
      #
      # @param [String] name The name of the plugin
      def add_go_plugin(name, **opts)
        @data["go_plugin"][name] = {
          "source" => opts[:source]
        }

        save!
      end

      # Remove a plugin that is installed from the state file.
      #
      # @param [String] name The name of the plugin
      def remove_go_plugin(name)
        @data["go_plugin"].delete(name)

        save!
      end

      # @return [Boolean] go plugin is present in this state file
      def has_go_plugin?(name)
        @data["go_plugin"].key?(name)
      end

      # This returns a hash of installed go plugins according to the state
      # file. Note that this may _not_ directly match over to actually
      # installed plugins.
      #
      # @return [Hash]
      def installed_go_plugins
        @data["go_plugin"]
      end

      # Add a plugin that is installed to the state file.
      #
      # @param [String] name The name of the plugin
      def add_plugin(name, **opts)
        @data["ruby"]["installed"][name] = {
          "ruby_version"          => RUBY_VERSION,
          "vagrant_version"       => Vagrant::VERSION,
          "gem_version"           => opts[:version] || "",
          "require"               => opts[:require] || "",
          "sources"               => opts[:sources] || [],
          "installed_gem_version" => opts[:installed_gem_version],
          "env_local"             => !!opts[:env_local]
        }

        save!
      end

      # Adds a RubyGems index source to look up gems.
      #
      # @param [String] url URL of the source.
      def add_source(url)
        @data["ruby"]["sources"] ||= []
        @data["ruby"]["sources"] |= [url]
        save!
      end

      # This returns a hash of installed plugins according to the state
      # file. Note that this may _not_ directly match over to actually
      # installed gems.
      #
      # @return [Hash]
      def installed_plugins
        @data["ruby"]["installed"]
      end

      # Returns true/false if the plugin is present in this state file.
      #
      # @return [Boolean]
      def has_plugin?(name)
        @data["ruby"]["installed"].key?(name)
      end

      # Remove a plugin that is installed from the state file.
      #
      # @param [String] name The name of the plugin.
      def remove_plugin(name)
        @data["ruby"]["installed"].delete(name)
        save!
      end

      # Remove a source for RubyGems.
      #
      # @param [String] url URL of the source
      def remove_source(url)
        @data["ruby"]["sources"] ||= []
        @data["ruby"]["sources"].delete(url)
        save!
      end

      # Returns the list of RubyGems sources that will be searched for
      # plugins.
      #
      # @return [Array<String>]
      def sources
        @data["ruby"]["sources"] || []
      end

      # This saves the state back into the state file.
      def save!
        Tempfile.open(@path.basename.to_s, @path.dirname.to_s) do |f|
          f.binmode
          f.write(JSON.dump(@data))
          f.fsync
          f.chmod(0644)
          f.close
          FileUtils.mv(f.path, @path)
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

      # This upgrades the internal data representation from V1 to V2
      def upgrade_v1!
        @data.delete("version")
        new_data = {
          "version" => "2",
          "ruby" => @data,
          "go_plugin" => {}
        }

        save!
      end
    end
  end
end
