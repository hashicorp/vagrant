require 'optparse'

module VagrantPlugins
  module CommandSnapshot
    module Command
      class List < Vagrant.plugin("2", :command)
        def execute
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant snapshot list [options] [vm-name]"
            o.separator ""
            o.separator "List all snapshots taken for a machine."
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          with_target_vms(argv) do |vm|
            if !vm.id
              vm.ui.info(I18n.t("vagrant.commands.common.vm_not_created"))
              next
            end

            if !vm.provider.capability?(:snapshot_list)
              raise Vagrant::Errors::SnapshotNotSupported
            end

            snapshots = vm.provider.capability(:snapshot_list)
            if snapshots.empty?
              vm.ui.output(I18n.t("vagrant.actions.vm.snapshot.list_none"))
              vm.ui.detail(I18n.t("vagrant.actions.vm.snapshot.list_none_detail"))
              next
            end

            snapshots.each do |snapshot|
              vm.ui.output(snapshot, prefix: false)
            end
          end

          # Success, exit status 0
          0
        end
      end
    end
  end
end
