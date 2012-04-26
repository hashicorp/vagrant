require 'optparse'

module VagrantPlugins
  module CommandBox
    module Command
      class Add < Vagrant::Command::Base
        def execute
          options = {}

          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant box add <name> <url>"
            opts.separator ""

            opts.on("-f", "--force", "Overwrite an existing box if it exists.") do |f|
              options[:force] = f
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          raise Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length < 2

          # If we're force adding, then be sure to destroy any existing box if it
          # exists.
          if options[:force]
            existing = @env.boxes.find(argv[0])
            existing.destroy if existing
          end

          @env.boxes.add(argv[0], argv[1])

          # Success, exit status 0
          0
        end
      end
    end
  end
end
