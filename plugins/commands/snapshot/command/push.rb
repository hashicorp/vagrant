require 'json'
require 'optparse'

require_relative "push_shared"

module VagrantPlugins
  module CommandSnapshot
    module Command
      class Push < Vagrant.plugin("2", :command)
        include PushShared

        def execute
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant snapshot push [options] [vm-name]"
            o.separator ""
            o.separator "Take a snapshot of the current state of the machine and 'push'"
            o.separator "it onto the stack of states. You can use `vagrant snapshot pop`"
            o.separator "to restore back to this state at any time."
            o.separator ""
            o.separator "If you use `vagrant snapshot save` or restore at any point after"
            o.separator "a push, pop will still bring you back to this pushed state."
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          return shared_exec(argv, method(:push))
        end
      end
    end
  end
end
