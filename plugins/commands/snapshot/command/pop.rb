require 'json'
require 'optparse'

require_relative "push_shared"

module VagrantPlugins
  module CommandSnapshot
    module Command
      class Pop < Vagrant.plugin("2", :command)
        include PushShared

        def execute
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant snapshot pop [options] [vm-name]"
            o.separator ""
            o.separator "Restore state that was pushed with `vagrant snapshot push`."
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          return shared_exec(argv, method(:pop))
        end
      end
    end
  end
end
