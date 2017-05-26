require 'optparse'

module VagrantPlugins
  module CommandSnapshot
    module Command
      class Save < Vagrant.plugin("2", :command)
        def execute
          options = {}
          options[:force] = false

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant snapshot save [options] [vm-name] <name>"
            o.separator ""
            o.separator "Take a snapshot of the current state of the machine. The snapshot"
            o.separator "can be restored via `vagrant snapshot restore` at any point in the"
            o.separator "future to get back to this exact machine state."
            o.separator ""
            o.separator "Snapshots are useful for experimenting in a machine and being able"
            o.separator "to rollback quickly."

            o.on("-f", "--force", "Replace snapshot without confirmation") do |f|
              options[:force] = f
            end
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
            if !vm.provider.capability?(:snapshot_list)
              raise Vagrant::Errors::SnapshotNotSupported
            end

            snapshot_list = vm.provider.capability(:snapshot_list)

            if !snapshot_list.include? name
              vm.action(:snapshot_save, snapshot_name: name)
            elsif options[:force]
              # not a unique snapshot name
              vm.action(:snapshot_delete, snapshot_name: name)
              vm.action(:snapshot_save, snapshot_name: name)
            else
              raise Vagrant::Errors::SnapshotConflictFailed
            end
          end

          # Success, exit status 0
          0
        end
      end
    end
  end
end
