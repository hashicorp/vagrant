require 'optparse'

require_relative "base"

module VagrantPlugins
  module CommandPlugin
    module Command
      class Install < Base
        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant plugin install <name> [-h]"
            o.separator ""

            o.on("--entry-point NAME", String,
                 "The name of the entry point file for loading the plugin.") do |entry_point|
              options[:entry_point] = entry_point
            end

            o.on("--plugin-prerelease",
                 "Allow prerelease versions of this plugin.") do |plugin_prerelease|
              options[:plugin_prerelease] = plugin_prerelease
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

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          raise Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length < 1

          # Install the gem
          action(Action.action_install, {
            :plugin_entry_point => options[:entry_point],
            :plugin_prerelease  => options[:plugin_prerelease],
            :plugin_version     => options[:plugin_version],
            :plugin_sources     => options[:plugin_sources],
            :plugin_name        => argv[0]
          })

          # Success, exit status 0
          0
        end
      end
    end
  end
end
