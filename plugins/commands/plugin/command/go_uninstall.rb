require 'optparse'

require_relative "base"

module VagrantPlugins
  module CommandPlugin
    module Command
      class GoUninstall < Base
        def execute
          options = {}
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant plugin gouninstall <name> [<name2> <name3> ...] [-h]"
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp if argv.length < 1

          # Uninstall the plugins
          argv.each do |entry|
            action(Action.action_go_uninstall, plugin_name: entry)
          end

          # Success, exit status 0
          0
        end
      end
    end
  end
end
