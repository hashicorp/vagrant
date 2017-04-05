module VagrantPlugins
  module CommandPlugin
    module Command
      module MixinInstallOpts
        def build_install_opts(o, options)
          options[:plugin_sources] = Vagrant::Bundler::DEFAULT_GEM_SOURCES.dup

          o.on("--entry-point NAME", String,
               "The name of the entry point file for loading the plugin.") do |entry_point|
            options[:entry_point] = entry_point
          end

          o.on("--plugin-clean-sources",
            "Remove all plugin sources defined so far (including defaults)") do |clean|
            options[:plugin_sources] = [] if clean
          end

          o.on("--plugin-source PLUGIN_SOURCE", String,
               "Add a RubyGems repository source") do |plugin_source|
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
