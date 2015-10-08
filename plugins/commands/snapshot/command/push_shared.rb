require 'json'

module VagrantPlugins
  module CommandSnapshot
    module Command
      module PushShared
        def shared_exec(argv, m)
          with_target_vms(argv) do |vm|
            if !vm.id
              vm.ui.info("Not created. Cannot push snapshot state.")
              next
            end

            vm.env.lock("machine-snapshot-stack") do
              m.call(vm)
            end
          end

          0
        end

        def push(machine)
          snapshot_name = "push_#{Time.now.to_i}_#{rand(10000)}"

          # Save the snapshot. This will raise an exception if it fails.
          machine.action(:snapshot_save, snapshot_name: snapshot_name)
        end

        def pop(machine)
          # By reverse sorting, we should be able to find the first
          # pushed snapshot.
          name = nil
          snapshots = machine.provider.capability(:snapshot_list)
          snapshots.sort.reverse.each do |snapshot|
            if snapshot =~ /^push_\d+_\d+$/
              name = snapshot
              break
            end
          end

          # If no snapshot was found, we never pushed
          if !name
            machine.ui.info(I18n.t("vagrant.commands.snapshot.no_push_snapshot"))
            return
          end

          # Restore the snapshot and tell the provider to delete it as well.
          machine.action(
            :snapshot_restore,
            snapshot_name: name,
            snapshot_delete: true)
        end
      end
    end
  end
end
