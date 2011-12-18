require 'optparse'

module Vagrant
  module Command
    class BoxAdd < Base
      def execute
        options = {}

        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant box add <name> <url>"
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @env.boxes.add(argv[0], argv[1])
      end
    end
  end
end
