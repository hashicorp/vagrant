require 'optparse'

module VagrantPlugins
  module CommandSnapshot
    module Command
      class List < Vagrant.plugin("2", :command)
        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant snapshot list [options] [vm-name]"
            o.separator ""
            o.separator "List all snapshots taken for a machine."
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          with_target_vms(argv) do |vm|
            vm.action(:snapshot_list)
          end

          # Success, exit status 0
          0
        end
      end
    end
  end
end
