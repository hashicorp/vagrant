require 'optparse'

module VagrantPlugins
  module CommandBox
    module Command
      class Repackage < Vagrant::Command::Base
        def execute
          options = {}

          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant box repackage <name>"
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          raise Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length < 1

          b = @env.boxes.find(argv[0])
          raise Vagrant::Errors::BoxNotFound, :name => argv[0] if !b
          b.repackage

          # Success, exit status 0
          0
        end
      end
    end
  end
end
