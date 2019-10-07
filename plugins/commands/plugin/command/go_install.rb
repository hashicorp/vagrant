require 'optparse'

require_relative "base"

module VagrantPlugins
  module CommandPlugin
    module Command
      class GoInstall < Base

        def execute
          options = { verbose: false }

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant plugin goinstall <name> <source>"
            o.separator ""

            o.on("--verbose", "Enable verbose output for plugin installation") do |v|
              options[:verbose] = v
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          if argv.length != 2
            raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp
          end

          plugin_name, plugin_source = argv

          action(Action.action_go_install,
            plugin_name: plugin_name,
            plugin_source: plugin_source
          )

          # Success, exit status 0
          0
        end
      end
    end
  end
end
