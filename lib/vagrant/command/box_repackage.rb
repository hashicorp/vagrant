require 'optparse'

module Vagrant
  module Command
    class BoxRepackage < Base
      def execute
        options = {}

        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant box repackage <name>"
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        b = @env.boxes.find(argv[0])
        raise Errors::BoxNotFound, :name => argv[0] if !b
        b.repackage
      end
    end
  end
end
