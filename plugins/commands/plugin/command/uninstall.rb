require 'optparse'

require_relative "base"

module VagrantPlugins
  module CommandPlugin
    module Command
      class Uninstall < Base
        def execute
          options = {}
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant plugin uninstall <name> [<name2> <name3> ...] [-h]"

            o.on("--local", "Remove plugin from local project") do |l|
              options[:local] = l
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp if argv.length < 1

          # Uninstall the gems
          argv.each do |gem|
            action(Action.action_uninstall, plugin_name: gem, local: options[:local])
          end

          # Success, exit status 0
          0
        end
      end
    end
  end
end
