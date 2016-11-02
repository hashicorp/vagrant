require 'optparse'

require_relative "base"

module VagrantPlugins
  module CommandPlugin
    module Command
      class Repair < Base
        def execute
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant plugin repair [-h]"
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp if argv.length > 0

          # Attempt to repair installed plugins
          action(Action.action_repair)

          # Success, exit status 0
          0
        end
      end
    end
  end
end
