require 'optparse'

require 'vagrant'

require Vagrant.source_root.join("plugins/commands/up/start_mixins")

module VagrantPlugins
  module CommandSnapshot
    module Command
      class Restore < Vagrant.plugin("2", :command)

        include VagrantPlugins::CommandUp::StartMixins

        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant snapshot restore [options] [vm-name] <name>"
            o.separator ""
            build_start_options(o, options)
            o.separator "Restore a snapshot taken previously with snapshot save."
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          if argv.empty? || argv.length > 2
            raise Vagrant::Errors::CLIInvalidUsage,
              help: opts.help.chomp
          end

          # Validate the provisioners
          validate_provisioner_flags!(options, argv)

          name = argv.pop
          options[:snapshot_name] = name

          with_target_vms(argv) do |vm|
            if !vm.provider.capability?(:snapshot_list)
              raise Vagrant::Errors::SnapshotNotSupported
            end

            snapshot_list = vm.provider.capability(:snapshot_list)

            if snapshot_list.include? name
              vm.action(:snapshot_restore, options)
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
