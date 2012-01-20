require 'optparse'

module Vagrant
  module Command
    class BoxAdd < Base
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
        raise Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length < 2

        # If we're force adding, then be sure to destroy any existing box if it
        # exists.
        if options[:force]
          existing = @env.boxes.find(argv[0])
          existing.destroy if existing
        end

        @env.boxes.add(argv[0], argv[1])
      end
    end
  end
end
