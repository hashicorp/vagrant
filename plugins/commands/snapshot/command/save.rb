require 'optparse'

module VagrantPlugins
  module CommandSnapshot
    module Command
      class Save < Vagrant.plugin("2", :command)
        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant snapshot save [options] [vm-name] <name>"
            o.separator ""
            o.separator "Take a snapshot of the current state of the machine. The snapshot"
            o.separator "can be restored via `vagrant snapshot restore` at any point in the"
            o.separator "future to get back to this exact machine state."
            o.separator ""
            o.separator "Snapshots are useful for experimenting in a machine and being able"
            o.separator "to rollback quickly."
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          if argv.empty? || argv.length > 2
            raise Vagrant::Errors::CLIInvalidUsage,
              help: opts.help.chomp
          end

          name = argv.pop
          with_target_vms(argv) do |vm|
            vm.action(:snapshot_save, snapshot_name: name)
          end

          # Success, exit status 0
          0
        end
      end
    end
  end
end
