require 'optparse'

require_relative "base"
require_relative "mixin_install_opts"

module VagrantPlugins
  module CommandPlugin
    module Command
      class Install < Base
        include MixinInstallOpts

        def execute
          options = { verbose: false }

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant plugin install <name>... [-h]"
            o.separator ""
            build_install_opts(o, options)

            o.on("--verbose", "Enable verbose output for plugin installation") do |v|
              options[:verbose] = v
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp if argv.length < 1

          # Install the gem
          argv.each do |name|
            action(Action.action_install, {
              plugin_entry_point: options[:entry_point],
              plugin_version:     options[:plugin_version],
              plugin_sources:     options[:plugin_sources],
              plugin_name:        name,
              plugin_verbose:     options[:verbose]
            })
          end

          # Success, exit status 0
          0
        end
      end
    end
  end
end
