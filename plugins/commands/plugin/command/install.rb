require 'optparse'

require_relative "base"

module VagrantPlugins
  module CommandPlugin
    module Command
      class Install < Base
        def execute
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant plugin install <name> [-h]"
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          raise Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length < 1

          # Install the gem
          action(Action.action_install, :plugin_name => argv[0])

          # Success, exit status 0
          0
        end
      end
    end
  end
end
