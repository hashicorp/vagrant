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

        b = @env.boxes.find(argv[0])
        raise Errors::BoxNotFound, :name => argv[0] if !b
        b.destroy
      end
    end
  end
end
