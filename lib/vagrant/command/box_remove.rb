require 'optparse'

module Vagrant
  module Command
    class BoxRemove < Base
      def execute
        options = {}

        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant box remove <name>"
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv
        raise Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length < 1

        b = @env.boxes.find(argv[0])
        raise Errors::BoxNotFound, :name => argv[0] if !b
        b.destroy

        # Success, exit status 0
        0
       end
    end
  end
end
