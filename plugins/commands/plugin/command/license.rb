require 'optparse'

require_relative "base"

module VagrantPlugins
  module CommandPlugin
    module Command
      class License < Base
        def execute
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant plugin license <name> <license-file> [-h]"
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp if argv.length < 2

          # License the plugin
          action(Action.action_license, {
            plugin_license_path: argv[1],
            plugin_name:         argv[0]
          })

          # Success, exit status 0
          0
        end
      end
    end
  end
end
