require 'optparse'

require_relative "base"

module VagrantPlugins
  module CommandPlugin
    module Command
      class Repair < Base
        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant plugin repair [-h]"

            o.on("--local", "Repair plugins in local project") do |l|
              options[:env_local] = l
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp if argv.length > 0

          if Vagrant::Plugin::Manager.instance.local_file
            action(Action.action_repair_local, env: @env)
          end

          # Attempt to repair installed plugins
          action(Action.action_repair, options)

          # Success, exit status 0
          0
        end
      end
    end
  end
end
