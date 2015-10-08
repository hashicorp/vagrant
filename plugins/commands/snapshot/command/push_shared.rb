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

          # Success! Write the resulting stack out
          modify_snapshot_stack(machine) do |stack|
            stack << snapshot_name
          end
        end

        def pop(machine)
          modify_snapshot_stack(machine) do |stack|
            name = stack.pop

            # Restore the snapshot and tell the provider to delete it as well.
            machine.action(
              :snapshot_restore,
              snapshot_name: name,
              snapshot_delete: true)
          end
        end

        protected

        def modify_snapshot_stack(machine)
          # Get the stack
          snapshot_stack = []
          snapshot_file = machine.data_dir.join("snapshot_stack")
          snapshot_stack = JSON.parse(snapshot_file.read) if snapshot_file.file?

          # Yield it so it can be modified
          yield snapshot_stack

          # Write it out
          snapshot_file.open("w+") do |f|
            f.write(JSON.dump(snapshot_stack))
          end
        end
      end
    end
  end
end
