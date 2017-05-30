module VagrantPlugins
  module PluginAutoInstaller
    class Config  < Vagrant.plugin("2", :config)
      def initialize
        @manifest = {}
      end

      def plugin_manifest
        @manifest
      end

      def add_plugin_manifest(other)
        @manifest.merge!( self.normalize_manifest other )
      end

      def require_plugin(*plugin_list)
        self.add_plugin_manifest( { required: [*plugin_list] } )
      end

      def prohibit_plugin(*plugin_list)
        self.add_plugin_manifest( { prohibited: [*plugin_list] } )
      end

      def validate(machine)
        # Go through each of the configuration keys and validate
        errors = Hash.new { |h, k| h[k] = [] }
        @manifest.each do |plugin, expectation|
          if (plugin.class != String) || plugin.match(/^(.*\s.*|required|prohibited)?$/)
            errors["auto_installer.add_plugin_manifest"] << "Plugin name '#{plugin}' invalid"
          end
          if not [ :required, :prohibited ].include?(expectation)
            errors["auto_installer.add_plugin_manifest"] <<  "Invalid plugin expectation '#{expectation}' for plugin '#{plugin}'. Use :required or :prohibited only!"
          end
        end
        errors
      end

      def valid?
        self.validate(nil).empty?
      end

      def to_s
        "Required Plugin List"
      end

      protected

      def normalize_manifest(hash_map)
        # Transform data format variations to cannonical format
        hash_map ||= []
        if hash_map.class == Array
          hash_map = { required: hash_map }
        end
        if not hash_map.keys.select {|k| [ :required, :prohibited ].include?(k) }.empty?
          hash_map = {}.tap do |h|
            hash_map.each do |k, a|
              [*a].each { |v| h[v] = k }
            end
          end
        end
        hash_map
      end

    end
  end
end
