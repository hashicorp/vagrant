module VagrantPlugins
  module CommandPlugin
    module Command
      module MixinInstallOpts
        def build_install_opts(o, options)
          o.on("--entry-point NAME", String,
               "The name of the entry point file for loading the plugin.") do |entry_point|
            options[:entry_point] = entry_point
          end

          # @deprecated
          o.on("--plugin-prerelease",
               "Allow prerelease versions of this plugin.") do |plugin_prerelease|
            puts "--plugin-prelease is deprecated and will be removed in the next"
            puts "version of Vagrant. It has no effect now. Use the '--plugin-version'"
            puts "flag to get a specific pre-release version."
            puts
          end

          o.on("--plugin-source PLUGIN_SOURCE", String,
               "Add a RubyGems repository source") do |plugin_source|
            options[:plugin_sources] ||= []
            options[:plugin_sources] << plugin_source
          end

          o.on("--plugin-version PLUGIN_VERSION", String,
               "Install a specific version of the plugin") do |plugin_version|
            options[:plugin_version] = plugin_version
          end
        end
      end
    end
  end
end
