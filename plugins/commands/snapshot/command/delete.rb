require 'optparse'

module VagrantPlugins
  module CommandSnapshot
    module Command
      class Delete < Vagrant.plugin("2", :command)
        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant snapshot delete [options] [vm-name] <name>"
            o.separator ""
            o.separator "Delete a snapshot taken previously with snapshot save."
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

            if snapshot_list.include? name
              vm.action(:snapshot_delete, snapshot_name: name)
            else
              raise Vagrant::Errors::SnapshotNotFound,
                snapshot_name: name,
                machine: vm.name.to_s
            end
          end

          # Success, exit status 0
          0
        end
      end
    end
  end
end
